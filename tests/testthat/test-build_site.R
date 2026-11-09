test_that("build_site renders the books then builds the site", {
  dir <- local_book_env()
  suppressMessages(create_book("a_fr", path_reports = dir))
  withr::local_dir(dir)
  calls <- list()
  local_mocked_bindings(
    run_renders = function(renders, workers) {
      calls <<- c(calls, lapply(renders, function(x) {
        list(x$label, render_output_dir(x))
      }))
    },
    .package = "kquarto.r"
  )
  local_mocked_bindings(
    pkgdown_init_site = function(...) NULL,
    pkgdown_build_site = function(...) "built",
    pkgdown_dst_path = function(override) override$destination
  )
  build_site(path_reports = ".", path_site = "public")
  expect_length(calls, 1)
  expect_equal(calls[[1]][[1]], "a_fr")
  # normalizePath() uses backslashes on Windows
  expect_match(calls[[1]][[2]], "public[/\\\\]reports[/\\\\]a_fr$")
  expect_true(file.exists("_pkgdown.yml"))
})

test_that("build_site renders the presentations in the site", {
  dir <- local_book_env()
  dir.create(file.path(dir, "reports"))
  dir.create(file.path(dir, "presentations"))
  suppressMessages(create_book(
    "a_fr", path_reports = file.path(dir, "reports")
  ))
  suppressMessages(create_presentation(
    "point",
    path_presentations = file.path(dir, "presentations"),
    title = "Point"
  ))
  withr::local_dir(dir)
  rendered <- list()
  local_mocked_bindings(
    run_renders = function(renders, workers) {
      rendered <<- renders
      mock_render_slides(renders)
    },
    .package = "kquarto.r"
  )
  local_mocked_bindings(
    pkgdown_init_site = function(...) NULL,
    pkgdown_build_site = function(...) "built",
    pkgdown_dst_path = function(override) override$destination
  )
  expect_equal(
    build_site(path_reports = "reports", path_site = "public"), "built"
  )
  # the book and the presentation in the same queue
  expect_equal(
    vapply(rendered, function(x) x$label, ""), c("a_fr", "point")
  )
  expect_true(file.exists("public/presentations/point/index.html"))
  config <- yaml::read_yaml("_pkgdown.yml")
  expect_equal(
    config$navbar$components$presentations$menu[[1]]$href,
    "presentations/point/index.html"
  )
})

test_that("build_site renders the books or the presentations only", {
  dir <- local_book_env()
  dir.create(file.path(dir, "reports"))
  dir.create(file.path(dir, "presentations"))
  suppressMessages(create_book(
    "a_fr", path_reports = file.path(dir, "reports")
  ))
  suppressMessages(create_presentation(
    "point",
    path_presentations = file.path(dir, "presentations"),
    title = "Point"
  ))
  withr::local_dir(dir)
  rendered <- character()
  local_mocked_bindings(
    run_renders = function(renders, workers) {
      rendered <<- c(rendered, vapply(renders, function(x) x$label, ""))
      mock_render_slides(renders)
    },
    .package = "kquarto.r"
  )
  inits <- 0
  local_mocked_bindings(
    pkgdown_init_site = function(...) inits <<- inits + 1,
    pkgdown_build_site = function(...) "built",
    pkgdown_dst_path = function(override) override$destination
  )

  build_site(render_presentations = FALSE)
  expect_equal(rendered, "a_fr")
  # the menu of the presentations not rendered is kept
  config <- yaml::read_yaml("_pkgdown.yml")
  expect_equal(
    config$navbar$components$presentations$menu[[1]]$href,
    "presentations/point/index.html"
  )
  expect_equal(config$navbar$structure$left, c("reports", "presentations"))

  rendered <- character()
  build_site(render_reports = FALSE)
  expect_equal(rendered, "point")
  expect_equal(yaml::read_yaml("_pkgdown.yml"), config)

  # neither: the books and presentations rendered elsewhere (e.g. other CI
  # jobs) are only added to the navbar
  unlink("_pkgdown.yml")
  rendered <- character()
  expect_equal(
    build_site(render_reports = FALSE, render_presentations = FALSE), "built"
  )
  expect_length(rendered, 0)
  expect_equal(yaml::read_yaml("_pkgdown.yml"), config)
  # pkgdown recognises the site folder, filled by the other jobs
  expect_equal(inits, 3)
})

test_that("build_site gives path_site to pkgdown, dev folder included", {
  dir <- local_book_env()
  suppressMessages(create_book("a_fr", path_reports = dir))
  withr::local_dir(dir)
  calls <- list()
  built <- NULL
  local_mocked_bindings(
    run_renders = function(renders, workers) {
      calls <<- c(calls, lapply(renders, render_output_dir))
    },
    .package = "kquarto.r"
  )
  local_mocked_bindings(
    pkgdown_init_site = function(...) NULL,
    pkgdown_build_site = function(...) built <<- list(...),
    # a development version: pkgdown writes in <destination>/dev
    pkgdown_dst_path = function(override) {
      file.path(override$destination, "dev")
    }
  )
  build_site(path_reports = ".", path_site = "site")
  expect_match(calls[[1]], "site[/\\\\]dev[/\\\\]reports[/\\\\]a_fr$")
  expect_equal(built$override, list(destination = "site"))

  # an override given by the caller is kept
  build_site(
    path_reports = ".", path_site = "site",
    override = list(destination = "other", url = "u")
  )
  expect_equal(built$override, list(destination = "other", url = "u"))
})

test_that("build_site always renders the HTML, then the extra formats", {
  dir <- local_book_env()
  dir.create(file.path(dir, "reports"))
  dir.create(file.path(dir, "presentations"))
  suppressMessages(create_book(
    c("a_fr", "b_fr"), path_reports = file.path(dir, "reports"),
    author = "A"
  ))
  suppressMessages(create_book(
    "c_fr", path_reports = file.path(dir, "reports"), author = "A",
    formats = c("html", "typst")
  ))
  suppressMessages(create_presentation(
    c("point", "bilan"),
    path_presentations = file.path(dir, "presentations")
  ))
  suppressMessages(create_presentation(
    "plus", path_presentations = file.path(dir, "presentations"),
    formats = c("revealjs", "beamer")
  ))
  withr::local_dir(dir)
  passes <- list()
  local_mocked_bindings(
    run_renders = function(renders, workers) {
      passes[[length(passes) + 1]] <<- lapply(renders, function(x) {
        list(x$label, x$args$output_format, render_output_dir(x))
      })
      for (render in renders) {
        out <- render_output_dir(render)
        if (!is.null(out)) {
          file.create(file.path(
            out, if (identical(render$args$output_format, "typst")) {
              "book.pdf"
            } else {
              "index.html"
            }
          ))
        }
      }
      mock_render_slides(renders)
    },
    .package = "kquarto.r"
  )
  local_mocked_bindings(
    pkgdown_init_site = function(...) NULL,
    pkgdown_build_site = function(...) "built",
    pkgdown_dst_path = function(override) override$destination
  )

  build_site(output_format = "typst")
  # HTML pass: every book and presentation; then the books with typst
  expect_length(passes, 2)
  expect_equal(
    vapply(passes[[1]], function(x) x[[2]], ""),
    c(rep("html", 3), rep("revealjs", 3))
  )
  expect_equal(vapply(passes[[2]], function(x) x[[1]], ""), "c_fr")
  expect_equal(passes[[2]][[1]][[2]], "typst")
  # the extra files are added to the HTML
  expect_true(file.exists("public/reports/c_fr/index.html"))
  expect_true(file.exists("public/reports/c_fr/book.pdf"))
  expect_false(file.exists("public/reports/a_fr/book.pdf"))

  passes <- list()
  build_site(output_format = "beamer")
  expect_length(passes, 2)
  expect_equal(vapply(passes[[2]], function(x) x[[1]], ""), "plus")
  expect_equal(passes[[2]][[1]][[2]], "beamer")

  # "all": a single pass
  passes <- list()
  build_site(output_format = "all")
  expect_length(passes, 1)
  expect_true(all(vapply(passes[[1]], function(x) x[[2]], "") == "all"))
})

test_that("build_site gives output_format to Quarto only, not to pkgdown", {
  dir <- local_book_env()
  suppressMessages(create_book("a_fr", path_reports = dir))
  withr::local_dir(dir)
  built <- NULL
  local_mocked_bindings(
    run_renders = function(renders, workers) NULL,
    .package = "kquarto.r"
  )
  local_mocked_bindings(
    pkgdown_init_site = function(...) NULL,
    pkgdown_build_site = function(...) built <<- list(...),
    pkgdown_dst_path = function(override) override$destination
  )
  build_site(path_reports = ".", output_format = "typst")
  expect_null(built$output_format)
})

test_that("build_site only builds the site without book or presentation", {
  dir <- local_book_env()
  withr::local_dir(dir)
  local_mocked_bindings(
    run_renders = function(renders, workers) stop("nothing to render"),
    .package = "kquarto.r"
  )
  inits <- 0
  local_mocked_bindings(
    pkgdown_init_site = function(...) inits <<- inits + 1,
    pkgdown_build_site = function(...) "built",
    pkgdown_dst_path = function(override) override$destination
  )
  expect_message(
    expect_equal(build_site(), "built"), "nothing to render"
  )
  expect_equal(inits, 0)
  expect_false(file.exists("_pkgdown.yml"))
})
