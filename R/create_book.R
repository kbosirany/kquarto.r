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
#'   template (see [list_templates_book()]), a template shipped by another
#'   package as `"pkg::name"`, or the path to a folder that contains a
#'   `_quarto.yml`. Defaults to the option `kquarto.r.template`, or
#'   `"default"`.
#' @param chapters Optional character vector of chapter names. Each one
#'   creates a numbered chapter file after `index.qmd` with
#'   [create_book_chapter()], e.g. `chapitre-01-introduction.qmd`. A
#'   chapter whose file already exists is not created again.
#' @param chapter_prefix Prefix of the chapter files. By default
#'   `"chapitre"` when `lang` is French, `"chapter"` otherwise.
#' @param output_dir Output folder of the rendered book, relative to the
#'   report folder (`project: output-dir`).
#' @param ... Additional fields merged (recursively) into `_quarto.yml`, e.g.
#'   `format = list(html = list(theme = "flatly"))` or
#'   `book = list(chapters = c("index.qmd", "methodes.qmd"))`.
#' @param overwrite If `FALSE` (the default), an error is raised when a
#'   report folder already contains a `_quarto.yml`. If `TRUE`, the
#'   `_quarto.yml` and the template files are overwritten; chapters already
#'   listed in the old `_quarto.yml` whose file still exists are kept in
#'   `book: chapters`, after those of the template.
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
#'   author = "Kevin Orlando",
#'   chapters = c("Introduction", "M\u00e9thodes", "R\u00e9sultats")
#' )
#' list.files(tmp, recursive = TRUE)
create_book <- function(dirname_reports,
                        path = ".",
                        title = NULL,
                        author = NULL,
                        lang = "fr",
                        date = NULL,
                        template = getOption("kquarto.r.template", "default"),
                        output_dir = "_book",
                        chapters = NULL,
                        chapter_prefix = NULL,
                        ...,
                        overwrite = FALSE) {
  check_dirnames(dirname_reports)
  if (!dir.exists(path)) {
    stop("`path` does not exist: ", path, call. = FALSE)
  }
  titles <- resolve_titles(title, dirname_reports)
  if (!is.null(chapters) && (!is.character(chapters) || anyNA(chapters))) {
    stop("`chapters` must be a character vector.", call. = FALSE)
  }
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
    old_chapters <- existing_chapters(report_dir)
    dir.create(report_dir, recursive = TRUE, showWarnings = FALSE)
    copy_dir(
      template_path, report_dir,
      overwrite = overwrite, exclude = "_quarto.yml"
    )

    config <- template_config
    config$project$type <- "book"
    config$project$`output-dir` <- output_dir
    config$book$title <- titles[[i]]
    if (!is.null(author)) config$book$author <- as.list(author)
    if (!is.null(date)) config$book$date <- date
    if (!is.null(lang)) config$lang <- lang
    if (length(extra) > 0) config <- utils::modifyList(config, extra)
    config$book$chapters <- merge_chapters(config$book$chapters, old_chapters)

    write_quarto_yml(config, file.path(report_dir, "_quarto.yml"))
    add_lines(
      file.path(report_dir, ".gitignore"),
      c("/.quarto/", paste0("/", output_dir, "/"))
    )

    prefix <- chapter_prefix %||% chapter_prefix(config$lang)
    for (chapter in chapters) {
      pattern <- paste0(
        "^", escape_regex(prefix), "-[0-9]+-", slugify(chapter), "\\.qmd$"
      )
      if (length(list.files(report_dir, pattern = pattern)) > 0) next
      suppressMessages(create_book_chapter(
        dirname_reports[[i]], chapter, path = path, prefix = chapter_prefix
      ))
    }
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

existing_chapters <- function(report_dir) {
  yml <- file.path(report_dir, "_quarto.yml")
  if (!file.exists(yml)) {
    return(list())
  }
  chapters <- as.list(yaml::read_yaml(yml)$book$chapters)
  is_kept <- function(x) {
    !is.character(x) || file.exists(file.path(report_dir, x))
  }
  Filter(is_kept, chapters)
}

merge_chapters <- function(chapters, old_chapters) {
  chapters <- as.list(chapters)
  is_new <- function(x) !any(vapply(chapters, identical, logical(1), x))
  new <- Filter(is_new, old_chapters)
  c(chapters, new)
}

check_dirnames <- function(dirname_reports) {
  if (!is.character(dirname_reports) || length(dirname_reports) == 0 ||
      anyNA(dirname_reports) || any(dirname_reports == "")) {
    stop(
      "`dirname_reports` must be a non-empty character vector.",
      call. = FALSE
    )
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
  existing <- character()
  if (file.exists(file)) existing <- readLines(file, warn = FALSE)
  new <- setdiff(lines, existing)
  if (length(new) > 0) {
    writeLines(c(existing, new), file)
  }
  invisible(new)
}

escape_regex <- function(x) {
  gsub("([.|()\\^{}+$*?\\[\\]\\\\])", "\\\\\\1", x, perl = TRUE)
}
