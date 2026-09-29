#' Render Quarto book reports
#'
#' Calls [quarto::quarto_render()] on each report folder.
#'
#' @param dirname_reports Report folder names, relative to `path`. By
#'   default, every book found in `path` (see [list_books()]).
#' @param path Folder containing the report folders.
#' @param output_dir Where the rendered book is written. `NULL` (the default)
#'   keeps the `output-dir` of the `_quarto.yml`, i.e. `_book/` inside the
#'   report folder. Otherwise a path relative to each report folder, e.g.
#'   `"../../docs/rapport"`.
#' @param output_format Output format(s) passed to Quarto, e.g. `"html"`,
#'   `"pdf"` or `"all"`. `NULL` renders the formats of the `_quarto.yml`.
#' @param quiet Whether to suppress Quarto output.
#' @param ... Other arguments passed to [quarto::quarto_render()].
#'
#' @return The paths of the output folders, invisibly.
#' @export
#'
#' @examples
#' \dontrun{
#' create_book("rapport")
#' render_book("rapport")
#' render_book("rapport", output_dir = "../docs/rapport")
#' }
render_book <- function(dirname_reports = NULL,
                        path = ".",
                        output_dir = NULL,
                        output_format = NULL,
                        quiet = FALSE,
                        ...) {
  if (is.null(dirname_reports)) {
    dirname_reports <- list_books(path)
    if (length(dirname_reports) == 0) {
      stop("No Quarto book found in: ", path, call. = FALSE)
    }
  }
  check_dirnames(dirname_reports)
  report_dirs <- file.path(path, dirname_reports)
  missing <- !file.exists(file.path(report_dirs, "_quarto.yml"))
  if (any(missing)) {
    stop(
      "No `_quarto.yml` in: ", paste(dirname_reports[missing], collapse = ", "),
      ". Create the book with `create_book()` first.",
      call. = FALSE
    )
  }
  if (is.null(quarto_bin())) {
    stop(
      "The Quarto CLI was not found. Install it from https://quarto.org.",
      call. = FALSE
    )
  }

  dots <- list(...)
  quarto_args <- dots$quarto_args
  dots$quarto_args <- NULL
  if (!is.null(output_dir)) {
    quarto_args <- c(quarto_args, "--output-dir", output_dir)
  }

  outputs <- character(length(report_dirs))
  for (i in seq_along(report_dirs)) {
    report_dir <- normalizePath(report_dirs[[i]])
    args <- c(
      list(
        input = report_dir,
        output_format = output_format,
        quiet = quiet,
        quarto_args = quarto_args
      ),
      dots
    )
    do.call(quarto_render, args)
    outputs[[i]] <- file.path(report_dir, output_dir %||% book_output_dir(report_dir))
  }
  invisible(outputs)
}

book_output_dir <- function(report_dir) {
  config <- yaml::read_yaml(file.path(report_dir, "_quarto.yml"))
  config$project$`output-dir` %||% "_book"
}

# Wrappers around quarto, so that tests can mock them.
quarto_render <- function(...) {
  quarto::quarto_render(...)
}

quarto_bin <- function() {
  quarto::quarto_path()
}

`%||%` <- function(x, y) if (is.null(x)) y else x
