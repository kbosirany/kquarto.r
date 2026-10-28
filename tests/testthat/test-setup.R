local_reports <- function(env = parent.frame()) {
  dir <- normalizePath(withr::local_tempdir(.local_envir = env))
  book <- file.path(dir, "reports", "rapport")
  dir.create(file.path(book, "sub"), recursive = TRUE)
  writeLines("setup_value <- 42", file.path(book, "setup.R"))
  dir
}

test_that("source_report_setup() finds the setup from the project root", {
  dir <- local_reports()
  env <- new.env()
  setup <- withr::with_dir(dir, source_report_setup("rapport", envir = env))
  expect_equal(env$setup_value, 42)
  expect_equal(setup, file.path(dir, "reports", "rapport", "setup.R"))
})

test_that("source_report_setup() finds the setup from the book and below", {
  dir <- local_reports()
  for (from in c("reports/rapport", "reports/rapport/sub", "reports")) {
    env <- new.env()
    withr::with_dir(
      file.path(dir, from), source_report_setup("rapport", envir = env)
    )
    expect_equal(env$setup_value, 42)
  }
})

test_that("source_report_setup() works for a book outside path_reports", {
  dir <- withr::local_tempdir()
  book <- file.path(dir, "rapport")
  dir.create(book)
  writeLines("setup_value <- 1", file.path(book, "setup.R"))
  env <- new.env()
  withr::with_dir(book, source_report_setup("rapport", envir = env))
  expect_equal(env$setup_value, 1)
})

test_that("source_report_setup() evaluates in the global env by default", {
  dir <- local_reports()
  withr::defer(rm("setup_value", envir = globalenv()))
  withr::with_dir(dir, source_report_setup("rapport"))
  expect_equal(get("setup_value", envir = globalenv()), 42)
})

test_that("source_report_setup() fails with a clear message", {
  dir <- local_reports()
  expect_error(
    withr::with_dir(dir, source_report_setup("autre")),
    "No `setup.R` found for the report `autre`"
  )
  expect_error(source_report_setup(c("a", "b")), "single non-empty string")
})
