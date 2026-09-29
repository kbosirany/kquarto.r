#' Create one or several Quarto book reports
#'
#' Creates a folder for each report in `dirname_reports`, copies the files of
#' `template` into it and writes a `_quarto.yml` (project of type `book`)
#' filled with the given title, author, language, ...
#'
#' When `path` is the root of an R package (it contains a `DESCRIPTION`
#' file), the report folders are also added to `.Rbuildignore`.
#'
#' @param dirname_reports Character vector of report folder names, relative
#'   to `path`.
#' @param path Folder in which the report folders are created. Defaults to
#'   the working directory.
#' @param title Book title(s). By default the name of each report folder.
#'   Otherwise either a single title (only when one report is created), an
#'   unnamed vector of the same length as `dirname_reports`, or a vector
#'   named by the report folders.
#' @param author Character vector of authors, written in `book: author`.
#' @param lang Document language (`lang` field), e.g. `"fr"` or `"en"`.
#' @param date Book date (`book: date`), e.g. `"today"` or
#'   `"last-modified"`. `NULL` to leave the template value.
#' @param template Template used to initialise the reports: the name of a
#'   template (see [list_templates_book()]) or the path to a folder that
#'   contains a `_quarto.yml`.
#' @param output_dir Output folder of the rendered book, relative to the
#'   report folder (`project: output-dir`).
#' @param ... Additional fields merged (recursively) into `_quarto.yml`, e.g.
#'   `format = list(html = list(theme = "flatly"))` or
#'   `book = list(chapters = c("index.qmd", "methodes.qmd"))`.
#' @param overwrite If `FALSE` (the default), an error is raised when a
#'   report folder already contains a `_quarto.yml`. If `TRUE`, the
#'   `_quarto.yml` and the template files are overwritten.
#'
#' @return The paths of the report folders, invisibly.
#' @export
#'
#' @examples
#' tmp <- tempfile()
#' dir.create(tmp)
#' create_book(
#'   c("rapport_technique", "note_synthese"),
#'   path = tmp,
#'   title = c(note_synthese = "Note de synthèse"),
#'   author = "Kevin"
#' )
#' list.files(tmp, recursive = TRUE)
create_book <- function(dirname_reports,
                        path = ".",
                        title = NULL,
                        author = NULL,
                        lang = "fr",
                        date = NULL,
                        template = "default",
                        output_dir = "_book",
                        ...,
                        overwrite = FALSE) {
  check_dirnames(dirname_reports)
  if (!dir.exists(path)) {
    stop("`path` does not exist: ", path, call. = FALSE)
  }
  titles <- resolve_titles(title, dirname_reports)
  template_path <- resolve_template(template)
  extra <- list(...)
  if (length(extra) > 0 && (is.null(names(extra)) || any(names(extra) == ""))) {
    stop("All arguments passed through `...` must be named.", call. = FALSE)
  }

  report_dirs <- file.path(path, dirname_reports)
  existing <- file.exists(file.path(report_dirs, "_quarto.yml"))
  if (!overwrite && any(existing)) {
    stop(
      "A `_quarto.yml` already exists in: ",
      paste(dirname_reports[existing], collapse = ", "),
      ". Use `overwrite = TRUE` to replace it.",
      call. = FALSE
    )
  }

  template_config <- yaml::read_yaml(file.path(template_path, "_quarto.yml"))

  for (i in seq_along(report_dirs)) {
    report_dir <- report_dirs[[i]]
    dir.create(report_dir, recursive = TRUE, showWarnings = FALSE)
    copy_dir(template_path, report_dir, overwrite = overwrite, exclude = "_quarto.yml")

    config <- template_config
    config$project$type <- "book"
    config$project$`output-dir` <- output_dir
    config$book$title <- titles[[i]]
    if (!is.null(author)) config$book$author <- as.list(author)
    if (!is.null(date)) config$book$date <- date
    if (!is.null(lang)) config$lang <- lang
    if (length(extra) > 0) config <- utils::modifyList(config, extra)

    write_quarto_yml(config, file.path(report_dir, "_quarto.yml"))
    add_lines(file.path(report_dir, ".gitignore"), c("/.quarto/", paste0("/", output_dir, "/")))
  }

  if (file.exists(file.path(path, "DESCRIPTION"))) {
    add_lines(
      file.path(path, ".Rbuildignore"),
      paste0("^", escape_regex(dirname_reports), "$")
    )
  }

  message("Book(s) created: ", paste(dirname_reports, collapse = ", "))
  invisible(normalizePath(report_dirs))
}

#' List the Quarto books of a folder
#'
#' @param path Folder to search in.
#' @param recursive Whether to search in subfolders.
#'
#' @return The names (relative to `path`) of the folders containing a
#'   `_quarto.yml` of type `book`.
#' @export
#'
#' @examples
#' tmp <- tempfile()
#' dir.create(tmp)
#' create_book(c("rapport_a", "rapport_b"), path = tmp)
#' list_books(tmp)
list_books <- function(path = ".", recursive = FALSE) {
  dirs <- list.dirs(path, full.names = FALSE, recursive = recursive)
  dirs <- dirs[dirs != "" & file.exists(file.path(path, dirs, "_quarto.yml"))]
  is_book <- vapply(dirs, function(d) {
    config <- yaml::read_yaml(file.path(path, d, "_quarto.yml"))
    identical(config$project$type, "book")
  }, logical(1))
  unname(dirs[is_book])
}

check_dirnames <- function(dirname_reports) {
  if (!is.character(dirname_reports) || length(dirname_reports) == 0 ||
      anyNA(dirname_reports) || any(dirname_reports == "")) {
    stop("`dirname_reports` must be a non-empty character vector.", call. = FALSE)
  }
  if (anyDuplicated(dirname_reports)) {
    stop("`dirname_reports` contains duplicated names.", call. = FALSE)
  }
  invisible(TRUE)
}

resolve_titles <- function(title, dirname_reports) {
  if (is.null(title)) {
    return(basename(dirname_reports))
  }
  if (!is.character(title)) {
    stop("`title` must be a character vector.", call. = FALSE)
  }
  if (!is.null(names(title))) {
    unknown <- setdiff(names(title), dirname_reports)
    if (length(unknown) > 0) {
      stop(
        "`title` has names that are not in `dirname_reports`: ",
        paste(unknown, collapse = ", "),
        call. = FALSE
      )
    }
    titles <- basename(dirname_reports)
    matched <- dirname_reports %in% names(title)
    titles[matched] <- title[dirname_reports[matched]]
    return(unname(titles))
  }
  if (length(title) != length(dirname_reports)) {
    stop(
      "An unnamed `title` must have the same length as `dirname_reports`. ",
      "Use a vector named by the report folders to set only some titles.",
      call. = FALSE
    )
  }
  title
}

write_quarto_yml <- function(config, file) {
  # Quarto reads YAML 1.2: write booleans as true/false, not yes/no.
  handlers <- list(logical = function(x) {
    value <- ifelse(x, "true", "false")
    class(value) <- "verbatim"
    value
  })
  yaml::write_yaml(config, file, handlers = handlers)
}

add_lines <- function(file, lines) {
  existing <- if (file.exists(file)) readLines(file, warn = FALSE) else character()
  new <- setdiff(lines, existing)
  if (length(new) > 0) {
    writeLines(c(existing, new), file)
  }
  invisible(new)
}

escape_regex <- function(x) {
  gsub("([.|()\\^{}+$*?\\[\\]\\\\])", "\\\\\\1", x, perl = TRUE)
}
