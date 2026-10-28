#' Source the setup of a report
#'
#' Sources the file `setup.R` of a book, from the setup chunk of its
#' chapters. The file is found from the working directory, so the same call
#' works during `quarto render` (the working directory is the book folder)
#' and when the chunks are run by hand (the working directory is often the
#' project root, or any folder of it).
#'
#' @param report Book folder name, e.g. `"04_run-intellirrig_fr"`.
#' @param file Name of the setup file.
#' @param path_reports Folder containing the book folders.
#' @param envir Environment where the file is evaluated. By default the
#'   global environment, where the chunks of a chapter are evaluated, so the
#'   objects it creates are available in the chunks.
#'
#' @return The path of the sourced file, invisibly.
#' @details The file is searched in each folder from the working directory up
#'   to the root of the file system: first `file` in the folder itself when it
#'   is named `report`, then `path_reports/report/file`. The first one found
#'   is sourced.
#' @export
#'
#' @examples
#' tmp <- tempfile()
#' dir.create(file.path(tmp, "reports", "rapport"), recursive = TRUE)
#' writeLines("setup_done <- TRUE", file.path(tmp, "reports/rapport/setup.R"))
#' withr::with_dir(tmp, source_report_setup("rapport", envir = environment()))
#' setup_done
source_report_setup <- function(report, file = "setup.R",
                                path_reports = "reports",
                                envir = globalenv()) {
  if (!is.character(report) || length(report) != 1 || is.na(report) ||
      !nzchar(report)) {
    stop("`report` must be a single non-empty string.", call. = FALSE)
  }
  setup <- find_report_setup(report, file, path_reports, getwd())
  if (is.null(setup)) {
    stop(
      "No `", file, "` found for the report `", report, "` from ",
      getwd(), " (looked in `", path_reports, "/", report,
      "` of this folder and its parents).",
      call. = FALSE
    )
  }
  source(setup, local = envir, encoding = "UTF-8")
  invisible(setup)
}

# The first `file` of the report found from `from` and its parents, or NULL.
find_report_setup <- function(report, file, path_reports, from) {
  dir <- normalizePath(from, winslash = "/", mustWork = FALSE)
  repeat {
    candidates <- c(
      if (basename(dir) == report) file.path(dir, file),
      file.path(dir, path_reports, report, file)
    )
    found <- candidates[file.exists(candidates)]
    if (length(found)) return(normalizePath(found[[1]], winslash = "/"))
    parent <- dirname(dir)
    if (identical(parent, dir)) return(NULL)
    dir <- parent
  }
}
