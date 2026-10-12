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
  expect_false(file.exists(file.path(dir, "b", "slides.qmd")))
  expect_false(file.exists(file.path(dir, "b", "template.yml")))

  header <- read_slides(files[[2]])$header
  expect_equal(header$title, "Séminaire B")
  expect_equal(header$author, "Kevin Orlando")
  expect_equal(header$lang, "fr")
  expect_true(header$format$revealjs$`slide-number`)
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
