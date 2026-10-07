#' Add the books to the navbar of a pkgdown site
#'
#' Writes a menu entry for each book into the `_pkgdown.yml` file, so that
#' [pkgdown::build_site()] links to the rendered books (see [build_site()]).
#' The books form one navbar menu, `reports`. When the books have several
#' languages (the `-en`/`-fr` suffix of their folder name), the menu has a
#' header by language (`English`, `Français`) followed by the titles of its
#' books; with a single language, or without any suffix, the titles are listed
#' without header. The components `reports_en` and `reports_fr` written by
#' former versions are removed.
#'
#' @param dirname_reports Book folder names, relative to `path`. By default,
#'   every book found in `path` (see [list_books()]).
#' @param path Folder containing the book folders.
#' @param titles Optional titles, as a character vector (or list) the same
#'   length as `dirname_reports`, possibly named by book folder. By default,
#'   the `book: title` of each `_quarto.yml`.
#' @param pkgdown_file Path to the pkgdown configuration file.
#' @param site_subdir Folder of the pkgdown site (relative to its root) where
#'   the books are rendered, used to build the links.
#' @param add_to_navbar Whether to add the components to
#'   `navbar: structure: left`.
#'
#' @return The YAML list written to `pkgdown_file`, invisibly.
#' @export
#'
#' @examples
#' \dontrun{
#' update_pkgdown_yml()
#' update_pkgdown_yml("rapport-fr", titles = "Mon rapport")
#' }
update_pkgdown_yml <- function(dirname_reports = NULL,
                               path = "reports",
                               titles = NULL,
                               pkgdown_file = "_pkgdown.yml",
                               site_subdir = "reports",
                               add_to_navbar = TRUE) {
  if (is.null(dirname_reports)) {
    dirname_reports <- list_books(path)
  }
  if (length(dirname_reports) == 0) {
    stop("No Quarto book found in: ", path, call. = FALSE)
  }
  check_dirnames(dirname_reports)

  titles <- if (is.null(titles)) {
    vapply(dirname_reports, function(d) {
      yml <- file.path(path, d, "_quarto.yml")
      title <- if (file.exists(yml)) yaml::read_yaml(yml)$book$title
      if (is.null(title)) d else as.character(title)
    }, character(1))
  } else {
    resolve_titles(unlist(titles), dirname_reports)
  }
  titles <- unname(titles)

  config <- list()
  if (file.exists(pkgdown_file)) {
    config <- yaml::read_yaml(pkgdown_file)
  }

  lang <- ifelse(
    grepl("-(fr|en)$", dirname_reports),
    sub(".*-(fr|en)$", "\\1", dirname_reports),
    ""
  )

  # former components, one by language
  old <- paste0("reports_", c("en", "fr"))
  config$navbar$components[old] <- NULL
  if (length(config$navbar$components) == 0) {
    config$navbar$components <- NULL
  }
  config$navbar$structure$left <- setdiff(config$navbar$structure$left, old)

  if (isTRUE(add_to_navbar)) {
    config$navbar$structure$left <- unique(c(
      config$navbar$structure$left,
      "reports"
    ))
  }

  config$navbar$components$reports <- list(
    text = "Reports",
    menu = reports_menu(
      lang,
      titles,
      file.path(site_subdir, dirname_reports, "index.html")
    )
  )
  yaml::write_yaml(config, pkgdown_file)
  invisible(config)
}

#' Build a pkgdown site including the rendered books
#'
#' Renders the books into the pkgdown destination folder, adds them to the
#' navbar (see [update_pkgdown_yml()]) and builds the site with
#' [pkgdown::build_site()].
#'
#' @param path Folder containing the book folders.
#' @param dest Destination folder of the pkgdown site (the `destination` of
#'   `_pkgdown.yml`).
#' @param site_subdir Folder of the site, relative to `dest`, where each book
#'   is rendered in its own sub-folder.
#' @param render_reports Whether to render the books and update the navbar.
#' @param build_readme Whether to rebuild the README with
#'   [devtools::build_readme()].
#' @param clean Whether to remove a book's previous output before rendering.
#' @param ... Other arguments passed to [pkgdown::build_site()].
#'
#' @return The result of [pkgdown::build_site()], invisibly.
#' @export
#'
#' @examples
#' \dontrun{
#' build_site()
#' }
build_site <- function(path = "reports",
                       dest = "public",
                       site_subdir = "reports",
                       render_reports = TRUE,
                       build_readme = FALSE,
                       clean = TRUE,
                       ...) {
  for (pkg in c("pkgdown", if (build_readme) "devtools")) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      stop("Package '", pkg, "' is required.", call. = FALSE)
    }
  }
  if (build_readme) {
    devtools::build_readme()
  }
  if (render_reports) {
    books <- list_books(path)
    if (length(books) == 0) {
      stop("No Quarto book found in: ", path, call. = FALSE)
    }
    # init_site() creates the marker file that lets pkgdown recognise the
    # destination folder once the books are written into it.
    pkgdown_init_site()
    for (book in books) {
      target <- file.path(dest, site_subdir, book)
      if (clean) unlink(target, recursive = TRUE)
      # The folder must exist for normalizePath() to return an absolute path
      # (otherwise Quarto resolves it relative to the book folder).
      dir.create(target, recursive = TRUE, showWarnings = FALSE)
      render_book(
        book,
        path = path,
        output_dir = normalizePath(target, mustWork = FALSE)
      )
    }
    update_pkgdown_yml(books, path = path, site_subdir = site_subdir)
  }
  invisible(pkgdown_build_site(...))
}

# Wrappers around pkgdown, so that tests can mock them.
pkgdown_init_site <- function(...) {
  pkgdown::init_site(...)
}

pkgdown_build_site <- function(...) {
  pkgdown::build_site(...)
}

# The menu of the books: a header by language when there are several
# languages (English, then French, then the books without language), none
# otherwise.
reports_menu <- function(lang, titles, hrefs) {
  languages <- c("English", "Fran\u00e7ais", "Other")
  names(languages) <- c("en", "fr", "")
  present <- intersect(names(languages), unique(lang))
  items <- function(i) {
    lapply(i, function(k) list(text = titles[[k]], href = hrefs[[k]]))
  }
  if (length(present) == 1) {
    return(items(seq_along(lang)))
  }
  menu <- list()
  for (l in present) {
    if (length(menu) > 0) {
      menu <- c(menu, list(list(text = "---------")))
    }
    menu <- c(menu, list(list(text = languages[[l]])), items(which(lang == l)))
  }
  menu
}
