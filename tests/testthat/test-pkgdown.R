test_that("update_pkgdown_yml writes one menu per language", {
  dir <- local_book_env()
  suppressMessages(create_book(
    c("a-fr", "b-fr", "c"),
    path = dir,
    title = c("A", "B", "C")
  ))
  file <- file.path(dir, "_pkgdown.yml")
  writeLines("url: https://example.org", file)

  update_pkgdown_yml(path = dir, pkgdown_file = file)
  config <- yaml::read_yaml(file)
  expect_equal(config$url, "https://example.org")
  expect_equal(config$navbar$structure$left, c("reports_fr", "reports"))
  menu <- config$navbar$components$reports_fr$menu
  expect_equal(menu[[1]]$text, "A")
  expect_equal(menu[[2]]$href, "reports/b-fr/index.html")
  expect_equal(config$navbar$components$reports$text, "Reports")

  # idempotent
  update_pkgdown_yml(path = dir, pkgdown_file = file)
  expect_equal(yaml::read_yaml(file), config)

  update_pkgdown_yml("a-fr", path = dir, titles = "Mon A", pkgdown_file = file)
  expect_equal(
    yaml::read_yaml(file)$navbar$components$reports_fr$menu[[1]]$text,
    "Mon A"
  )
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
