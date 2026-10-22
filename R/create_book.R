#' Create one or several Quarto book reports
#'
#' Creates a folder for each report in `dirname_reports`, copies the files of
#' `template` into it and writes a `_quarto.yml` (project of type `book`)
#' filled with the given title, author, language, ...
#'
#' When `path_reports` is the root of an R package (it contains a
#' `DESCRIPTION` file), the report folders are also added to `.Rbuildignore`;
#' when it is a folder of the root of a package (e.g. `reports/`), this
#' folder is added.
#'
#' @param dirname_reports Character vector of report folder names, relative
#'   to `path_reports`.
#' @param path_reports Folder in which the report folders are created.
#' @param title Book title(s). By default the name of each report folder.
#'   Otherwise either a single title (only when one report is created), an
#'   unnamed vector of the same length as `dirname_reports`, or a vector
#'   named by the report folders.
#' @param author Character vector of authors, written in `book: author`.
#' @param lang Document language (`lang` field), e.g. `"fr"` or `"en"`.
#' @param date Book date (`book: date`), e.g. `"today"` or
#'   `"last-modified"`. `NULL` to leave the template value.
#' @param template Template used to initialise the reports: the name of a
#'   template (see [list_templates_book()]), e.g. `"default"` or `"inrae"`
#'   (INRAE graphic charter), a template shipped by another
#'   package as `"pkg::name"`, or the path to a folder that contains a
#'   `_quarto.yml`. Defaults to the option `kquarto.r.template`, or
#'   `"default"`.
#' @param chapters Optional character vector of chapter names. Each one
#'   creates a numbered chapter file after `index.qmd` with
#'   [create_book_chapter()], e.g. `chapitre_01_introduction.qmd`. A
#'   chapter whose file already exists is not created again.
#' @param chapter_prefix Prefix of the chapter files. By default
#'   `"chapitre"` when `lang` is French, `"chapter"` otherwise.
#' @param output_dir Output folder of the rendered book, relative to the
#'   report folder (`project: output-dir`).
#' @param ... Additional fields merged (recursively) into `_quarto.yml`, e.g.
#'   `format = list(html = list(theme = "flatly"))` or
#'   `book = list(chapters = c("index.qmd", "methodes.qmd"))`.
#' @param formats Output formats of the book. `NULL` (the default) keeps
#'   those of the template (HTML for the shipped templates). `"typst"` adds
#'   a PDF built with Typst (bundled with Quarto, nothing to install) and
#'   `"pdf"` a PDF built with LaTeX (needs a LaTeX distribution, e.g.
#'   TinyTeX: `quarto install tinytex`). Both are styled like the template
#'   if it has a `typst.yml` / `pdf.yml`. `"html"` keeps the HTML format.
#'   E.g. `c("html", "pdf")`. Render with `render_book(output_format =
#'   "pdf")` or `"typst"`. The Typst PDF needs an `author`. When the HTML
#'   is combined with a PDF format, the HTML book gets a "Download PDF"
#'   icon in its sidebar (`book: downloads: [pdf]`), which links to the PDF
#'   rendered with `render_book(output_format = "all")`.
#' @param overwrite If `FALSE` (the default), an error is raised when a
#'   report folder already contains a `_quarto.yml`. If `TRUE`, the
#'   `_quarto.yml` and the template files are overwritten; chapters already
#'   listed in the old `_quarto.yml` whose file still exists are kept in
#'   `book: chapters`, after those of the template.
#' @param path Deprecated, use `path_reports`.
#'
#' @return The paths of the report folders, invisibly.
#' @export
#'
#' @examples
#' tmp <- tempfile()
#' dir.create(tmp)
#' create_book(
#'   c("rapport_technique", "note_synthese"),
#'   path_reports = tmp,
#'   title = c(note_synthese = "Note de synthèse"),
#'   author = "Kevin Orlando",
#'   chapters = c("Introduction", "M\u00e9thodes", "R\u00e9sultats")
#' )
#' list.files(tmp, recursive = TRUE)
create_book <- function(dirname_reports,
                        path_reports = "reports",
                        title = NULL,
                        author = NULL,
                        lang = "fr",
                        date = NULL,
                        template = getOption("kquarto.r.template", "default"),
                        output_dir = "_book",
                        chapters = NULL,
                        chapter_prefix = NULL,
                        ...,
                        formats = NULL,
                        overwrite = FALSE,
                        path = NULL) {
  path_reports <- renamed_arg(path_reports, path, "path_reports", "path")
  check_dirnames(dirname_reports)
  if (!dir.exists(path_reports)) {
    stop("`path_reports` does not exist: ", path_reports, call. = FALSE)
  }
  titles <- resolve_titles(title, dirname_reports)
  if (!is.null(chapters) && (!is.character(chapters) || anyNA(chapters))) {
    stop("`chapters` must be a character vector.", call. = FALSE)
  }
  check_formats(formats)
  template_path <- resolve_template(template)
  extra <- list(...)
  if (length(extra) > 0 && (is.null(names(extra)) || any(names(extra) == ""))) {
    stop("All arguments passed through `...` must be named.", call. = FALSE)
  }

  report_dirs <- file.path(path_reports, dirname_reports)
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
  if ("typst" %in% formats && is.null(author) &&
      is.null(template_config$book$author)) {
    warning(
      "The Typst (PDF) format of a book needs an author: ",
      "set `author`, or rendering will fail.",
      call. = FALSE
    )
  }

  for (i in seq_along(report_dirs)) {
    report_dir <- report_dirs[[i]]
    old_chapters <- existing_chapters(report_dir)
    dir.create(report_dir, recursive = TRUE, showWarnings = FALSE)
    copy_dir(
      template_path, report_dir,
      overwrite = overwrite,
      exclude = c("_quarto.yml", "pdf.yml", "typst.yml", "template.yml")
    )
    copy_shared(template_path, report_dir, overwrite = overwrite)

    config <- template_config
    config$project$type <- "book"
    config$project$`output-dir` <- output_dir
    config$book$title <- titles[[i]]
    if (!is.null(author)) config$book$author <- as.list(author)
    if (!is.null(date)) config$book$date <- date
    if (!is.null(lang)) config$lang <- lang
    config <- set_formats(config, formats, template_path)
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
        "^", escape_regex(prefix), "[-_][0-9]+[-_]", slugify(chapter),
        "\\.qmd$"
      )
      if (length(list.files(report_dir, pattern = pattern)) > 0) next
      suppressMessages(create_book_chapter(
        dirname_reports[[i]], chapter, path_reports = path_reports,
        prefix = chapter_prefix
      ))
    }
  }

  root <- dirname(normalizePath(path_reports))
  if (file.exists(file.path(path_reports, "DESCRIPTION"))) {
    add_lines(
      file.path(path_reports, ".Rbuildignore"),
      paste0("^", escape_regex(dirname_reports), "$")
    )
  } else if (file.exists(file.path(root, "DESCRIPTION"))) {
    add_lines(
      file.path(root, ".Rbuildignore"),
      paste0("^", escape_regex(basename(normalizePath(path_reports))), "$")
    )
  }

  message("Book(s) created: ", paste(dirname_reports, collapse = ", "))
  invisible(normalizePath(report_dirs))
}

#' List the Quarto books of a folder
#'
#' @param path_reports Folder to search in.
#' @param recursive Whether to search in subfolders.
#' @param path Deprecated, use `path_reports`.
#'
#' @return The names (relative to `path_reports`) of the folders containing a
#'   `_quarto.yml` of type `book`.
#' @export
#'
#' @examples
#' tmp <- tempfile()
#' dir.create(tmp)
#' create_book(c("rapport_a", "rapport_b"), path_reports = tmp)
#' list_books(tmp)
list_books <- function(path_reports = "reports", recursive = FALSE,
                       path = NULL) {
  path_reports <- renamed_arg(path_reports, path, "path_reports", "path")
  dirs <- list.dirs(path_reports, full.names = FALSE, recursive = recursive)
  dirs <- dirs[
    dirs != "" & file.exists(file.path(path_reports, dirs, "_quarto.yml"))
  ]
  is_book <- vapply(dirs, function(d) {
    config <- yaml::read_yaml(file.path(path_reports, d, "_quarto.yml"))
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

check_formats <- function(formats) {
  valid <- is.null(formats) ||
    (is.character(formats) && all(formats %in% c("html", "pdf", "typst")))
  if (!valid) {
    stop(
      "`formats` must be NULL or a subset of: html, pdf, typst.",
      call. = FALSE
    )
  }
  invisible(TRUE)
}

set_formats <- function(config, formats, template_path) {
  if (is.null(formats)) {
    return(config)
  }
  if (!"html" %in% formats) config$format$html <- NULL
  if ("html" %in% formats && any(c("pdf", "typst") %in% formats)) {
    config$book$downloads <-
      as.list(union(unlist(config$book$downloads), "pdf"))
  }
  for (format in intersect(c("pdf", "typst"), formats)) {
    file <- file.path(template_path, paste0(format, ".yml"))
    config$format[[format]] <- if (file.exists(file)) {
      yaml::read_yaml(file)
    } else {
      list(toc = TRUE, `number-sections` = TRUE, papersize = "a4")
    }
  }
  config
}

#' Add a PDF download to existing Quarto books
#'
#' Adds a PDF format to the `_quarto.yml` of existing books and a
#' "Download PDF" icon to the sidebar of their HTML version
#' (`book: downloads: [pdf]`). The other fields of the `_quarto.yml` are
#' kept. Render then all the formats with `render_book(output_format =
#' "all")`: the icon links to the PDF of the output folder.
#'
#' Interactive content (leaflet, plotly, DT, ...) has no PDF rendering:
#' show it only in the HTML with `::: {.content-visible when-format="html"}`
#' and give a static version for the PDF.
#'
#' @inheritParams create_book
#' @param dirname_reports Character vector of book folder names, relative to
#'   `path_reports`.
#' @param format PDF engine: `"typst"` (the default, bundled with Quarto) or
#'   `"pdf"` (LaTeX).
#' @param template Optional template whose `typst.yml` / `pdf.yml` styles
#'   the PDF (e.g. `"inrae"`). Its files missing from the book (e.g.
#'   `inrae.typ`, `_brand.yml`) are copied; existing files are not
#'   overwritten. `NULL` uses a plain style (table of contents, numbered
#'   sections, A4).
#'
#' @return The paths of the book folders, invisibly.
#' @export
#'
#' @examples
#' tmp <- tempfile()
#' dir.create(tmp)
#' create_book(
#'   "rapport", path_reports = tmp, template = "inrae", author = "Kevin"
#' )
#' add_pdf_download("rapport", path_reports = tmp, template = "inrae")
#' cat(readLines(file.path(tmp, "rapport", "_quarto.yml")), sep = "\n")
add_pdf_download <- function(dirname_reports,
                             path_reports = "reports",
                             format = c("typst", "pdf"),
                             template = NULL,
                             path = NULL) {
  path_reports <- renamed_arg(path_reports, path, "path_reports", "path")
  check_dirnames(dirname_reports)
  format <- match.arg(format)
  template_path <- if (is.null(template)) {
    file.path(tempfile(), "none")
  } else {
    resolve_template(template)
  }
  report_dirs <- file.path(path_reports, dirname_reports)
  ymls <- file.path(report_dirs, "_quarto.yml")
  missing <- !file.exists(ymls)
  if (any(missing)) {
    stop(
      "No `_quarto.yml` in: ", paste(dirname_reports[missing], collapse = ", "),
      call. = FALSE
    )
  }

  for (i in seq_along(report_dirs)) {
    # Keep the one-element lists (e.g. `chapters: [index.qmd]`) as lists.
    config <- yaml::read_yaml(ymls[[i]], handlers = list(seq = as.list))
    if (!identical(config$project$type, "book")) {
      stop("Not a Quarto book: ", dirname_reports[[i]], call. = FALSE)
    }
    if (format == "typst" && is.null(config$book$author)) {
      warning(
        "The Typst (PDF) format of a book needs an author: add ",
        "`book: author` to ", dirname_reports[[i]], "/_quarto.yml.",
        call. = FALSE
      )
    }
    if (!is.null(template)) {
      copy_dir(
        template_path, report_dirs[[i]],
        exclude = c(
          "_quarto.yml", "pdf.yml", "typst.yml", "template.yml", "index.qmd"
        )
      )
      copy_shared(template_path, report_dirs[[i]])
    }
    formats <- union(names(config$format) %||% "html", c("html", format))
    if (is.null(config$format[[format]])) {
      config <- set_formats(config, formats, template_path)
    } else {
      config$book$downloads <-
        as.list(union(unlist(config$book$downloads), "pdf"))
    }
    write_quarto_yml(config, ymls[[i]])
  }

  message("PDF download added to: ", paste(dirname_reports, collapse = ", "))
  invisible(normalizePath(report_dirs))
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
