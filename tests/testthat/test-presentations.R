test_that("presentation templates are typed and do not mix with books", {
  local_book_env()
  books <- list_templates_book()$name
  slides <- list_templates_presentation()$name
  expect_true(all(c("default", "inrae") %in% books))
  expect_true(all(c("default-presentation", "inrae-presentation") %in% slides))
  expect_false(any(slides %in% books))
  expect_error(
    resolve_template("inrae-presentation", "book"), "Unknown template"
  )
  expect_error(
    create_book("a", path = tempdir(), template = "default-presentation"),
    "Unknown template"
  )
  expect_error(
    create_presentation("a", path = tempdir(), template = "inrae"),
    "Unknown template"
  )
})

test_that("create_presentation writes the slides and the template files", {
  dir <- local_book_env()
  files <- suppressMessages(create_presentation(
    c("a", "b"),
    path = dir,
    title = c(b = "Séminaire B"),
    author = "Kevin Orlando",
    subtitle = "Sous-titre",
    template = "inrae-presentation"
  ))
  expect_equal(basename(files), c("a.qmd", "b.qmd"))
  expect_true(file.exists(file.path(dir, "b", "inrae-charte.scss")))
  expect_true(file.exists(file.path(dir, "b", "inrae-slides.scss")))
  expect_true(file.exists(file.path(dir, "b", "images", "logo-inrae.png")))
  # the masks of the INRAE PowerPoint template
  for (image in c("inrae-titre.png", "inrae-titre-vert.png", "inrae-pied.png")) {
    expect_true(file.exists(file.path(dir, "b", "images", image)))
  }
  expect_false(file.exists(file.path(dir, "b", "slides.qmd")))
  expect_false(file.exists(file.path(dir, "b", "template.yml")))

  header <- read_slides(files[[2]])$header
  expect_equal(header$title, "Séminaire B")
  expect_equal(header$author, "Kevin Orlando")
  expect_equal(header$lang, "fr")
  expect_equal(header$format$revealjs$`slide-number`, "c")
  expect_equal(read_slides(files[[1]])$header$title, "a")
  expect_true(any(grepl("^## ", read_slides(files[[1]])$body)))

  expect_equal(list_presentations(dir), c("a", "b"))
  expect_equal(list_books(dir), character())
  expect_error(
    create_presentation("a", path = dir, template = "inrae-presentation"),
    "overwrite"
  )
})

test_that("presentation templates can be saved and reused", {
  dir <- local_book_env()
  path <- suppressMessages(
    create_template_presentation("unite", from = "inrae-presentation")
  )
  # A saved template is self-contained
  expect_true(file.exists(file.path(path, "inrae-charte.scss")))
  expect_equal(template_info(path)$type, "presentation")
  expect_null(template_info(path)$shared)
  expect_true("unite" %in% list_templates_presentation()$name)
  expect_false("unite" %in% list_templates_book()$name)

  suppressMessages(create_presentation("x", path = dir, template = "unite"))
  expect_true(file.exists(file.path(dir, "x", "images", "logo-inrae.png")))

  expect_error(remove_template_book("unite"), "No user template")
  expect_true(remove_template_presentation("unite"))
})

test_that("render_presentation calls quarto_render on the slides", {
  dir <- local_book_env()
  suppressMessages(create_presentation(c("a", "b"), path = dir))
  calls <- list()
  local_mocked_bindings(
    quarto_bin = function() "/usr/bin/quarto",
    quarto_render = function(...) calls[[length(calls) + 1]] <<- list(...)
  )
  out <- render_presentation(path = dir, quiet = TRUE)
  expect_length(calls, 2)
  expect_equal(
    calls[[1]]$input, normalizePath(file.path(dir, "a", "a.qmd"))
  )
  expect_equal(basename(out), c("a.html", "b.html"))
  expect_error(render_presentation("nope", path = dir), "create_presentation")
})

test_that("an INRAE presentation renders", {
  skip_on_cran()
  skip_if(is.null(quarto::quarto_path()), "Quarto CLI not installed")
  dir <- local_book_env()
  suppressMessages(create_presentation(
    "seminaire", path = dir, author = "Kevin Orlando",
    template = "inrae-presentation"
  ))
  render_presentation("seminaire", path = dir, quiet = TRUE)
  expect_true(file.exists(file.path(dir, "seminaire", "seminaire.html")))
})

test_that("create_presentation can add the beamer (LaTeX PDF) format", {
  dir <- local_book_env()
  suppressMessages(create_presentation(
    c("a", "b"), path = dir, template = "inrae-presentation",
    formats = c("revealjs", "beamer")
  ))
  expect_true(file.exists(file.path(dir, "a", "inrae-beamer.tex")))
  expect_false(file.exists(file.path(dir, "a", "beamer.yml")))
  format <- read_slides(file.path(dir, "a", "a.qmd"))$header$format
  expect_named(format, c("revealjs", "beamer"))
  expect_equal(format$beamer$`include-in-header`, "inrae-beamer.tex")

  suppressMessages(create_presentation(
    "c", path = dir, formats = "beamer"
  ))
  format <- read_slides(file.path(dir, "c", "c.qmd"))$header$format
  expect_named(format, "beamer")
  expect_equal(format$beamer$aspectratio, 169)

  expect_error(
    create_presentation("d", path = dir, formats = "typst"), "no slides"
  )
  expect_equal(list_presentations(dir), c("a", "b"))
})

test_that("an INRAE presentation renders to PDF with beamer", {
  skip_on_cran()
  skip_if(is.null(quarto::quarto_path()), "Quarto CLI not installed")
  skip_if(
    !any(nzchar(Sys.which(c("lualatex", "xelatex", "pdflatex")))),
    "No LaTeX installation found"
  )
  dir <- local_book_env()
  suppressMessages(create_presentation(
    "s", path = dir, template = "inrae-presentation", formats = "beamer"
  ))
  out <- render_presentation("s", path = dir, output_format = "beamer",
                             quiet = TRUE)
  expect_equal(basename(out), "s.pdf")
  expect_true(file.exists(out))
})

test_that("render_presentation copies the output of the slides", {
  dir <- local_book_env()
  suppressMessages(create_presentation("point", path = dir))
  local_mocked_bindings(
    quarto_bin = function(...) "quarto",
    quarto_render = function(input, ...) {
      writeLines("<html></html>", sub("\\.qmd$", ".html", input))
    },
    .package = "kquarto.r"
  )
  out <- file.path(dir, "site")
  render_presentation("point", path = dir, output_dir = out)
  expect_true(file.exists(file.path(out, "point", "index.html")))
  expect_false(file.exists(file.path(out, "point", "point.pdf")))
})

test_that("render_presentation gives the PowerPoint output", {
  dir <- local_book_env()
  suppressMessages(create_presentation("point", path = dir))
  local_mocked_bindings(
    quarto_bin = function(...) "quarto",
    quarto_render = function(input, ...) {
      writeLines("x", sub("\\.qmd$", ".pptx", input))
    },
    .package = "kquarto.r"
  )
  out <- file.path(dir, "site")
  rendered <- render_presentation(
    "point", path = dir, output_format = "pptx", output_dir = out
  )
  expect_equal(basename(rendered), "point.pptx")
  expect_true(file.exists(file.path(out, "point", "point.pptx")))
  expect_false(file.exists(file.path(out, "point", "index.html")))
})
