#' Build a pkgdown site including the rendered books
#'
#' Renders the books and the presentations into the pkgdown site, adds them
#' to the navbar (see [update_pkgdown_yml()]) and builds the site with
#' [pkgdown::build_site()] in `path_site`.
#'
#' The site of a development version (pkgdown `development: mode`) is
#' written by pkgdown in `<path_site>/dev`: the books and the presentations
#' go there too, so that the links of its navbar work.
#'
#' @param path_reports Folder containing the book folders.
#' @param path_site Folder of the pkgdown site, e.g. `"public"` (GitLab
#'   Pages) or `"docs"` (GitHub Pages). It is given to pkgdown as its
#'   `destination`.
#' @param subdir_reports Folder of the site where each book is rendered in
#'   its own sub-folder.
#' @param render_reports Whether to render the books.
#' @param render_presentations Whether to render the presentations. The
#'   navbar is updated with every book and presentation found, rendered or
#'   not (the ones not rendered keep their previous output in the site, e.g.
#'   rendered by other CI jobs).
#' @param path_presentations Folder containing the presentation folders (see
#'   [create_presentation()]). Without this folder, or without any
#'   presentation in it, there is no presentation on the site.
#' @param subdir_presentations Folder of the site where each presentation is
#'   rendered in its own sub-folder (`index.html`, and the PDF if the
#'   presentation has one).
#' @param build_readme Whether to rebuild the README with
#'   [devtools::build_readme()].
#' @param clean Whether to remove a book's previous output before rendering.
#' @param check_rendered Whether to stop if a book (with `render_reports =
#'   FALSE`) or a presentation (with `render_presentations = FALSE`) is not
#'   in the site yet, as rendered by [render_site_item()] in other CI jobs.
#' @param output_format Formats rendered in addition to the HTML, which is
#'   always rendered (`"html"` for the books, `"revealjs"` for the
#'   presentations), e.g. `"typst"`, `"pdf"` for the books or `"beamer"`,
#'   `"pptx"` for the presentations. Only given to [render_book()] and
#'   [render_presentation()], not to pkgdown. A book or presentation that does
#'   not declare a format is not rendered in it. `"all"` renders all the
#'   formats of each one. The additional files of a book are added to its
#'   folder in the site. Each format runs the code of the chapters again
#'   (`execute: freeze` does not share the results between formats): cache
#'   the slow computations in the chapters, e.g. with `saveRDS()`.
#' @param workers Number of books and presentations rendered at the same
#'   time, see [render_book()].
#' @param ... Other arguments passed to [pkgdown::build_site()].
#'
#' @return The result of [pkgdown::build_site()], invisibly.
#' @export
#'
#' @examples
#' \dontrun{
#' build_site()
#' }
build_site <- function(path_reports = "reports",
                       path_site = "public",
                       subdir_reports = "reports",
                       render_reports = TRUE,
                       path_presentations = "presentations",
                       subdir_presentations = "presentations",
                       render_presentations = TRUE,
                       build_readme = FALSE,
                       clean = TRUE,
                       output_format = NULL,
                       check_rendered = FALSE,
                       workers = getOption("kquarto.r.workers", 1L),
                       ...) {
  args <- list(...)
  # pkgdown writes in `path_site`, or in `<path_site>/dev` for a development
  # version: the books and the presentations go there too
  args$override$destination <- args$override$destination %||% path_site
  dest <- pkgdown_dst_path(args$override)
  for (pkg in c("pkgdown", if (build_readme) "devtools")) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      stop("Package '", pkg, "' is required.", call. = FALSE)
    }
  }
  if (build_readme) {
    devtools::build_readme()
  }
  # The navbar lists every book and presentation, also the ones not
  # rendered this time (their previous output stays in the site).
  books <- list_books(path_reports)
  presentations <- list_presentations(path_presentations)
  if (check_rendered) {
    not_rendered <- function(subdir, names) {
      index <- file.path(dest, subdir, names, "index.html")
      file.path(subdir, names)[!file.exists(index)]
    }
    missing <- c(
      if (!render_reports) not_rendered(subdir_reports, books),
      if (!render_presentations) {
        not_rendered(subdir_presentations, presentations)
      }
    )
    if (length(missing) > 0) {
      stop(
        "Not rendered in the site: ", paste(missing, collapse = ", "),
        ". Add them to the matrix of the CI, see `update_gitlab_ci()`.",
        call. = FALSE
      )
    }
  }
  has_items <- length(books) > 0 || length(presentations) > 0
  if ((render_reports || render_presentations) && !has_items) {
    # not an error: the site is just the one of the package
    message("No Quarto book or presentation found, nothing to render.")
  }
  if (has_items) {
    # init_site() creates the marker file that lets pkgdown recognise the
    # destination folder once the books are written into it, here or before
    # (e.g. by other CI jobs, without rendering here).
    pkgdown_init_site(override = args$override %||% list())
  }
  if ((render_reports || render_presentations) && has_items) {
    rendered <- if (render_presentations) presentations else character()
    rendered_books <- if (render_reports) books else character()
    extra <- extra_formats(output_format)
    # Pass 1: the HTML (or every format with "all"), the books and the
    # presentations in a single queue, so that `workers` renders them all at
    # the same time. A pass per additional format follows.
    items <- list()
    for (book in rendered_books) {
      target <- file.path(dest, subdir_reports, book)
      if (clean) unlink(target, recursive = TRUE)
      # The folder must exist for normalizePath() to return an absolute path
      # (otherwise Quarto resolves it relative to the book folder).
      dir.create(target, recursive = TRUE, showWarnings = FALSE)
      items <- c(items, list(item_passes(
        "book", book, path_reports, normalizePath(target), output_format
      )))
    }
    for (name in rendered) {
      items <- c(items, list(item_passes(
        "presentation", name, path_presentations, NULL, output_format
      )))
    }
    run_renders(unlist(lapply(items, `[[`, "main"), recursive = FALSE), workers)
    for (format in extra) {
      renders <- unlist(lapply(items, `[[`, format), recursive = FALSE)
      if (length(renders) == 0) {
        message("No book or presentation with the format: ", format)
        next
      }
      run_renders(renders, workers)
    }
    if (length(rendered) > 0) {
      target <- file.path(dest, subdir_presentations)
      if (clean) unlink(file.path(target, rendered), recursive = TRUE)
      dir.create(target, recursive = TRUE, showWarnings = FALSE)
      copy_presentation_outputs(
        rendered, file.path(path_presentations, rendered),
        normalizePath(target, mustWork = FALSE)
      )
    }
  }
  if (has_items) {
    update_pkgdown_yml(
      books,
      path_reports = path_reports,
      subdir_reports = subdir_reports,
      dirname_presentations = presentations,
      path_presentations = path_presentations,
      subdir_presentations = subdir_presentations
    )
  }
  invisible(do.call(pkgdown_build_site, args))
}

# The names of the formats of a book (`_quarto.yml`) or of slides (YAML
# header).
book_formats <- function(path_reports, book) {
  config <- yaml::read_yaml(file.path(path_reports, book, "_quarto.yml"))
  format_names(config$format)
}

presentation_formats <- function(path_presentations, name) {
  file <- file.path(path_presentations, name, paste0(name, ".qmd"))
  format_names(read_slides(file)$header$format)
}

format_names <- function(format) {
  if (is.character(format)) format else names(format)
}

# The format that is always rendered: `html` when declared (or when nothing
# is declared: Quarto's default), else `NULL`, the first declared format.
main_format <- function(declared, html) {
  if (length(declared) == 0 || html %in% declared) html else NULL
}

# Wrappers around pkgdown, so that tests can mock them.
pkgdown_init_site <- function(...) {
  pkgdown::init_site(...)
}

pkgdown_build_site <- function(...) {
  pkgdown::build_site(...)
}

# The folder where pkgdown writes the site of the package of the working
# directory: `destination`, or `<destination>/dev` for a development version.
pkgdown_dst_path <- function(override) {
  pkgdown::as_pkgdown(".", override = override)$dst_path
}
