#' Format a table for a Quarto book
#'
#' Renders a data frame as a styled, scrollable table in HTML output and as
#' a `booktabs` table in LaTeX/PDF output. It is meant to be called from the
#' chunks of the chapters of a book.
#'
#' @param x A data frame or a matrix.
#' @param is_html_output Whether the output is HTML. By default, detected
#'   with [knitr::is_html_output()] (or `TRUE` in an interactive session).
#' @param title Optional caption of the table.
#' @param height Height of the scroll box in HTML output, e.g. `"300px"`.
#'
#' @return A `knitr_kable` object.
#' @details In LaTeX output, only the first rows of `x` are kept
#'   (see [utils::head()]), as a long table does not fit in a page.
#' @export
#'
#' @examples
#' kable(head(iris), is_html_output = TRUE, title = "Iris")
#' kable(head(iris), is_html_output = FALSE)
kable <- function(
  x,
  is_html_output = knitr::is_html_output() || interactive(),
  title = NULL,
  height = "100%"
) {
  if (!is_html_output) {
    return(
      knitr::kable(
        utils::head(x), format = "latex", booktabs = TRUE, caption = title
      )
    )
  }

  tab <- kableExtra::kable(x, format = "pipe", caption = title)
  tab <- kableExtra::kable_styling(tab, font_size = 12)
  tab <- kableExtra::column_spec(tab, seq_len(ncol(x)), width = "auto")
  kableExtra::scroll_box(tab, width = "100%", height = height)
}
