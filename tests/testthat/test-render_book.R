test_that("render_book calls quarto_render with the right arguments", {
  dir <- local_book_env()
  suppressMessages(create_book(c("a", "b"), path_reports = dir))

  calls <- list()
  local_mocked_bindings(
    quarto_bin = function() "/usr/bin/quarto",
    quarto_render = function(...) calls[[length(calls) + 1]] <<- list(...)
  )

  out <- render_book(path_reports = dir, quiet = TRUE)
  expect_length(calls, 2)
  expect_equal(calls[[1]]$input, normalizePath(file.path(dir, "a")))
  expect_null(calls[[1]]$quarto_args)
  expect_true(calls[[1]]$quiet)
  expect_equal(out[[1]], file.path(normalizePath(file.path(dir, "a")), "_book"))

  calls <- list()
  out <- render_book(
    "b", path_reports = dir, output_dir = "../docs/b", output_format = "html",
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
  expect_error(render_book(path_reports = dir), "No Quarto book")
  expect_error(render_book("nope", path_reports = dir), "create_book")
  suppressMessages(create_book("a", path_reports = dir))
  expect_error(render_book("a", path_reports = dir), "Quarto CLI")
})

test_that("run_renders renders in parallel and reports the failures", {
  local_mocked_bindings(quarto_bin = function() "/usr/bin/quarto")
  dir <- withr::local_tempdir()
  renders <- lapply(c("a", "b", "c"), function(label) {
    list(label = label, args = list(file = file.path(dir, label)))
  })
  # stands for quarto::quarto_render() in the background sessions
  fun <- function(args) {
    cat("rendering", basename(args$file), "\n")
    if (basename(args$file) == "b") stop("b is broken")
    writeLines("done", args$file)
  }

  messages <- character()
  expect_error(
    withCallingHandlers(
      run_renders(renders, workers = 2, fun = fun),
      message = function(m) {
        messages <<- c(messages, conditionMessage(m))
        invokeRestart("muffleMessage")
      }
    ),
    "Rendering failed for: b[.]"
  )
  # the other renders are done anyway
  expect_true(all(file.exists(file.path(dir, c("a", "c")))))
  expect_false(file.exists(file.path(dir, "b")))
  log <- grep("^\n--- b", messages, value = TRUE)
  expect_match(log, "rendering b")
  expect_match(log, "b is broken")

  renders[[2]] <- NULL
  expect_silent(suppressMessages(run_renders(renders, workers = 4, fun = fun)))
})

test_that("render_book gives workers to run_renders", {
  dir <- local_book_env()
  suppressMessages(create_book(c("a", "b"), path_reports = dir))
  workers <- NULL
  local_mocked_bindings(run_renders = function(renders, workers) {
    workers <<- workers
  })
  render_book(path_reports = dir, workers = 2)
  expect_equal(workers, 2)
  withr::local_options(kquarto.r.workers = 3)
  render_book(path_reports = dir)
  expect_equal(workers, 3)
})

test_that("run_renders checks workers", {
  expect_error(run_renders(list(), workers = 0), "`workers`")
  expect_error(run_renders(list(), workers = 1.5), "`workers`")
  expect_error(run_renders(list(), workers = NA), "`workers`")
})

test_that("render_book renders a real book", {
  skip_on_cran()
  skip_if(is.null(quarto::quarto_path()), "Quarto CLI not installed")
  dir <- local_book_env()
  suppressMessages(create_book("a", path_reports = dir))
  out <- render_book("a", path_reports = dir, quiet = TRUE)
  expect_true(file.exists(file.path(out, "index.html")))
})

test_that("a book created with the INRAE template renders", {
  skip_on_cran()
  skip_if(is.null(quarto::quarto_path()), "Quarto CLI not installed")
  dir <- local_book_env()
  suppressMessages(create_book(
    "a", path_reports = dir, template = "inrae", chapters = "Introduction"
  ))
  out <- render_book("a", path_reports = dir, quiet = TRUE)
  expect_true(file.exists(file.path(out, "index.html")))
  expect_true(file.exists(file.path(out, "chapitre_01_introduction.html")))
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
    "a", path_reports = dir, template = "inrae", formats = "typst",
    author = "Kevin Orlando", chapters = "Introduction"
  ))
  cat(
    "\n```{r}\nknitr::kable(head(iris))\n```\n",
    file = file.path(dir, "a", "chapitre_01_introduction.qmd"),
    append = TRUE
  )
  out <- render_book(
    "a", path_reports = dir, output_format = "typst", quiet = FALSE
  )
  expect_length(list.files(out, pattern = "[.]pdf$"), 1)
})

test_that("a book renders to PDF with LaTeX", {
  skip_on_cran()
  skip_if(is.null(quarto::quarto_path()), "Quarto CLI not installed")
  skip_if(
    !any(nzchar(Sys.which(c("lualatex", "xelatex", "pdflatex")))),
    "No LaTeX installation found"
  )
  dir <- local_book_env()
  suppressMessages(create_book(
    "a", path_reports = dir, template = "inrae", formats = "pdf",
    chapters = "Introduction"
  ))
  out <- render_book(
    "a", path_reports = dir, output_format = "pdf", quiet = TRUE
  )
  expect_length(list.files(out, pattern = "[.]pdf$"), 1)
})
