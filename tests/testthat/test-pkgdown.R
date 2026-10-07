test_that("update_pkgdown_yml writes one menu, a header by language", {
  dir <- local_book_env()
  suppressMessages(create_book(
    c("a-fr", "b-fr", "a-en"),
    path = dir,
    title = c("A", "B", "A en")
  ))
  file <- file.path(dir, "_pkgdown.yml")
  writeLines(c("url: https://example.org", "navbar:", "  structure:",
               "    left: [intro, reports_fr, news]"), file)

  update_pkgdown_yml(path = dir, pkgdown_file = file)
  config <- yaml::read_yaml(file)
  expect_equal(config$url, "https://example.org")
  expect_equal(config$navbar$structure$left, c("intro", "news", "reports"))
  expect_equal(config$navbar$components$reports$text, "Reports")
  menu <- config$navbar$components$reports$menu
  expect_equal(
    vapply(menu, function(x) x$text, ""),
    c("English", "A en", "---------", "Fran\u00e7ais", "A", "B")
  )
  expect_equal(menu[[6]]$href, "reports/b-fr/index.html")
  expect_null(menu[[1]]$href)

  # idempotent
  update_pkgdown_yml(path = dir, pkgdown_file = file)
  expect_equal(yaml::read_yaml(file), config)

  update_pkgdown_yml("a-fr", path = dir, titles = "Mon A", pkgdown_file = file)
  menu <- yaml::read_yaml(file)$navbar$components$reports$menu
  expect_length(menu, 1)
  expect_equal(menu[[1]]$text, "Mon A")
})

test_that("update_pkgdown_yml errors without book", {
  dir <- local_book_env()
  expect_error(update_pkgdown_yml(path = dir), "No Quarto book")
})

test_that("build_site renders the books then builds the site", {
  dir <- local_book_env()
  suppressMessages(create_book("a-fr", path = dir))
  withr::local_dir(dir)
  calls <- list()
  local_mocked_bindings(
    render_book = function(dirname_reports, path, output_dir, ...) {
      calls[[length(calls) + 1]] <<- list(dirname_reports, output_dir)
    },
    .package = "kquarto.r"
  )
  local_mocked_bindings(
    pkgdown_init_site = function(...) NULL,
    pkgdown_build_site = function(...) "built"
  )
  build_site(path = ".", dest = "public")
  expect_length(calls, 1)
  expect_equal(calls[[1]][[1]], "a-fr")
  # normalizePath() uses backslashes on Windows
  expect_match(calls[[1]][[2]], "public[/\\\\]reports[/\\\\]a-fr$")
  expect_true(file.exists("_pkgdown.yml"))
})
