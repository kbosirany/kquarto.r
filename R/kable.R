#' Format a table for a Quarto book
#'
#' Renders a data frame as a styled, scrollable table in HTML output, and as
#' a plain full table in PDF output (Typst, LaTeX) or any other format. It
#' is meant to be called from the chunks of the chapters of a book.
#'
#' @param x A data frame or a matrix.
#' @param is_html_output Whether the output is HTML. By default, detected
#'   with [knitr::is_html_output()] (or `TRUE` in an interactive session).
#' @param title Optional caption of the table.
#' @param height Height of the scroll box in HTML output, e.g. `"300px"`.
#'
#' @return A `knitr_kable` object.
#' @details Outside HTML the whole table is written: a Markdown table
#'   (converted by Quarto, so it works with Typst, Word, ...) or, in LaTeX
#'   output, a `booktabs` table.
#'
#'   The HTML table needs the package kableExtra, which kquarto.r does not
#'   install: add it to the dependencies of the project whose books call
#'   `kable()`.
#' @export
#'
#' @examples
#' kable(head(iris), is_html_output = FALSE)
#' @examplesIf requireNamespace("kableExtra", quietly = TRUE)
#' kable(head(iris), is_html_output = TRUE, title = "Iris")
kable <- function(
  x,
  is_html_output = knitr::is_html_output() || interactive(),
  title = NULL,
  height = "100%"
) {
  if (!is_html_output) {
    if (knitr::is_latex_output()) {
      return(knitr::kable(
        x, format = "latex", booktabs = TRUE, longtable = TRUE,
        caption = title
      ))
    }
    return(knitr::kable(x, format = "pipe", caption = title))
  }

  if (!has_kableextra()) {
    stop(
      "Package 'kableExtra' is required for HTML tables: ",
      "install it and add it to the dependencies of your project.",
      call. = FALSE
    )
  }
  tab <- kableExtra::kable(x, format = "pipe", caption = title)
  tab <- kableExtra::kable_styling(tab, font_size = 12)
  tab <- kableExtra::column_spec(tab, seq_len(ncol(x)), width = "auto")
  kableExtra::scroll_box(tab, width = "100%", height = height)
}

# Wrapper, so that tests can mock it.
has_kableextra <- function() {
  requireNamespace("kableExtra", quietly = TRUE)
}
