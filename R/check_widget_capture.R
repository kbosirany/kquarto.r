# The PDF formats (Typst, LaTeX) cannot show an HTML widget (leaflet, plotly,
# DT...): knitr takes a screenshot of it with webshot2, which needs Chrome or
# Chromium. Without them Quarto stops with "Functions that produce HTML
# output found in document targeting typst output", which does not say what to
# install. The check warns before the render, for the books that need it.

widget_pattern <- paste(
  "leaflet", "plotly", "DT::", "reactable", "htmlwidgets", "htmltools",
  "highcharter", "dygraphs", "visNetwork", "mapview", "tmap", "kleaflet",
  "kplotly",
  sep = "|"
)

# Warns when a render of `renders` builds a PDF format of a book that uses
# widgets while the screenshots are not possible. Silent otherwise, and for
# the renders without a book folder (the slides).
check_widget_capture <- function(renders) {
  needing <- Filter(needs_widget_capture, renders)
  if (length(needing) == 0) {
    return(invisible(TRUE))
  }
  missing <- missing_capture_tools()
  if (length(missing) == 0) {
    return(invisible(TRUE))
  }
  labels <- vapply(needing, function(x) x$label, character(1))
  warning(
    "The PDF of ", paste(labels, collapse = ", "), " needs a screenshot of ",
    "the widgets (leaflet, plotly...), but ",
    paste(missing, collapse = " and "),
    " not available. Quarto will stop with \"Functions that produce HTML ",
    "output found in document targeting typst output\". Install the R ",
    "package with `install.packages(\"webshot2\")` and Google Chrome or ",
    "Chromium (e.g. on Debian/Ubuntu: `sudo apt-get install chromium`), or ",
    "set `CHROMOTE_CHROME` to the browser. Check with ",
    "`chromote::find_chrome()`.",
    call. = FALSE
  )
  invisible(FALSE)
}

needs_widget_capture <- function(render) {
  input <- render$args$input
  if (!is.character(input) || length(input) != 1 || !dir.exists(input)) {
    return(FALSE)
  }
  config_file <- file.path(input, "_quarto.yml")
  if (!file.exists(config_file)) {
    return(FALSE)
  }
  formats <- render_formats(render$args$output_format, config_file)
  if (!any(formats %in% c("typst", "pdf"))) {
    return(FALSE)
  }
  files <- list.files(
    input, pattern = "[.](qmd|Rmd|R)$", recursive = TRUE, full.names = TRUE
  )
  files <- files[!grepl("(^|/)_book/", files)]
  any(vapply(files, function(f) {
    any(grepl(widget_pattern, readLines(f, warn = FALSE)))
  }, logical(1)))
}

# The formats rendered: the `output_format` of the render ("all" or `NULL`:
# the formats of the `_quarto.yml`).
render_formats <- function(output_format, config_file) {
  if (!is.null(output_format) && !identical(output_format, "all")) {
    return(output_format)
  }
  names(yaml::read_yaml(config_file)$format)
}

# What is missing for the screenshots, to say in the warning.
missing_capture_tools <- function() {
  missing <- character()
  if (!has_package("webshot2")) {
    missing <- c(missing, "the R package webshot2 is")
  }
  if (!has_chrome()) {
    missing <- c(missing, "Chrome or Chromium is")
  }
  missing
}

# Wrappers so that the tests can mock them.
has_package <- function(package) requireNamespace(package, quietly = TRUE)

has_chrome <- function() {
  if (!has_package("chromote")) {
    return(FALSE)
  }
  path <- tryCatch(suppressWarnings(chromote::find_chrome()),
                   error = function(e) NULL)
  !is.null(path) && nzchar(path)
}
