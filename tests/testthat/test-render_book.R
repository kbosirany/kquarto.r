test_that("render_book calls quarto_render with the right arguments", {
  dir <- local_book_env()
  suppressMessages(create_book(c("a", "b"), path = dir))

  calls <- list()
  local_mocked_bindings(
    quarto_bin = function() "/usr/bin/quarto",
    quarto_render = function(...) calls[[length(calls) + 1]] <<- list(...)
  )

  out <- render_book(path = dir, quiet = TRUE)
  expect_length(calls, 2)
  expect_equal(calls[[1]]$input, normalizePath(file.path(dir, "a")))
  expect_null(calls[[1]]$quarto_args)
  expect_true(calls[[1]]$quiet)
  expect_equal(out[[1]], file.path(normalizePath(file.path(dir, "a")), "_book"))

  calls <- list()
  out <- render_book(
    "b", path = dir, output_dir = "../docs/b", output_format = "html",
    quarto_args = "--no-cache"
  )
  expect_equal(
    calls[[1]]$quarto_args,
    c("--no-cache", "--output-dir", "../docs/b")
  )
  expect_equal(calls[[1]]$output_format, "html")
})

test_that("render_book errors clearly", {
  dir <- local_book_env()
  local_mocked_bindings(quarto_bin = function() NULL)
  expect_error(render_book(path = dir), "No Quarto book")
  expect_error(render_book("nope", path = dir), "create_book")
  suppressMessages(create_book("a", path = dir))
  expect_error(render_book("a", path = dir), "Quarto CLI")
})

test_that("render_book renders a real book", {
  skip_on_cran()
  skip_if(is.null(quarto::quarto_path()), "Quarto CLI not installed")
  dir <- local_book_env()
  suppressMessages(create_book("a", path = dir))
  out <- render_book("a", path = dir, quiet = TRUE)
  expect_true(file.exists(file.path(out, "index.html")))
})

test_that("a book created with the INRAE template renders", {
  skip_on_cran()
  skip_if(is.null(quarto::quarto_path()), "Quarto CLI not installed")
  dir <- local_book_env()
  suppressMessages(create_book(
    "a", path = dir, template = "inrae", chapters = "Introduction"
  ))
  out <- render_book("a", path = dir, quiet = TRUE)
  expect_true(file.exists(file.path(out, "index.html")))
  expect_true(file.exists(file.path(out, "chapitre-01-introduction.html")))
})

test_that("a book renders to PDF with Typst", {
  skip_on_cran()
  skip_if(is.null(quarto::quarto_path()), "Quarto CLI not installed")
  version <- system2(quarto::quarto_path(), "--version", stdout = TRUE)
  skip_if(
    package_version(trimws(version[[1]])) < "1.4",
    "Typst books need Quarto >= 1.4"
  )
  dir <- local_book_env()
  suppressMessages(create_book(
    "a", path = dir, template = "inrae", formats = "typst",
    chapters = "Introduction"
  ))
  cat(
    "\n```{r}\nknitr::kable(head(iris))\n```\n",
    file = file.path(dir, "a", "chapitre-01-introduction.qmd"),
    append = TRUE
  )
  out <- render_book("a", path = dir, output_format = "typst", quiet = TRUE)
  expect_length(list.files(out, pattern = "[.]pdf$"), 1)
})
