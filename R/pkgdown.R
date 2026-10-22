#' Add the books to the navbar of a pkgdown site
#'
#' Writes a menu entry for each book into the `_pkgdown.yml` file, so that
#' [pkgdown::build_site()] links to the rendered books (see [build_site()]).
#' The books form one navbar menu, `reports`. Each book has a category:
#' `package` (the reference material about the package functions) when its
#' folder name starts with a number (`01_...`), `others` otherwise (project
#' report, meeting...); a `category: package` or `category: others` key in
#' its `_quarto.yml` overrides it. With both categories, the menu has a
#' header by category (`Package`, `Others`), suffixed by the language
#' (`[en]`, `[fr]`, the `_en`/`_fr` suffix of the folder name) when there
#' are several languages. With a single category, the menu has a header by
#' language (`English`, `Français`) when there are several languages, none
#' otherwise. The `package` items are sorted by folder name, the `others`
#' items by date (folder name starting with `YYYYMMDD`), most recent first,
#' then by folder name. The components `reports_en` and `reports_fr` written
#' by former versions are removed.
#'
#' @param dirname_reports Book folder names, relative to `path_reports`. By
#'   default, every book found in `path_reports` (see [list_books()]).
#' @param path_reports Folder containing the book folders.
#' @param titles Optional titles, as a character vector (or list) the same
#'   length as `dirname_reports`, possibly named by book folder. By default,
#'   the `book: title` of each `_quarto.yml`.
#' @param pkgdown_file Path to the pkgdown configuration file.
#' @param subdir_reports Folder of the pkgdown site (relative to its root)
#'   where the books are rendered, used to build the links.
#' @param add_to_navbar Whether to add the components to
#'   `navbar: structure: left`.
#' @param dirname_presentations Presentation folder names, relative to
#'   `path_presentations`. By default, every presentation found in
#'   `path_presentations` (see [list_presentations()]). They form the
#'   navbar menu `presentations`, titled after the `title` of their slides,
#'   with headers by category and language as the books (the `category` key
#'   overriding the category is in the YAML header of the slides); without
#'   any presentation, the menu is removed.
#' @param path_presentations Folder containing the presentation folders.
#' @param subdir_presentations Folder of the pkgdown site (relative to its
#'   root) where the presentations are rendered, used to build the links.
#' @param path Deprecated, use `path_reports`.
#' @param site_subdir Deprecated, use `subdir_reports`.
#' @param presentations Deprecated, use `dirname_presentations`.
#' @param presentations_path Deprecated, use `path_presentations`.
#' @param presentations_site_subdir Deprecated, use `subdir_presentations`.
#'
#' @return The YAML list written to `pkgdown_file`, invisibly.
#' @export
#'
#' @examples
#' \dontrun{
#' update_pkgdown_yml()
#' update_pkgdown_yml("rapport_fr", titles = "Mon rapport")
#' }
update_pkgdown_yml <- function(dirname_reports = NULL,
                               path_reports = "reports",
                               titles = NULL,
                               pkgdown_file = "_pkgdown.yml",
                               subdir_reports = "reports",
                               add_to_navbar = TRUE,
                               dirname_presentations = NULL,
                               path_presentations = "presentations",
                               subdir_presentations = "presentations",
                               path = NULL,
                               site_subdir = NULL,
                               presentations = NULL,
                               presentations_path = NULL,
                               presentations_site_subdir = NULL) {
  path <- renamed_arg(path_reports, path, "path_reports", "path")
  site_subdir <- renamed_arg(
    subdir_reports, site_subdir, "subdir_reports", "site_subdir"
  )
  presentations <- renamed_arg(
    dirname_presentations, presentations, "dirname_presentations",
    "presentations"
  )
  presentations_path <- renamed_arg(
    path_presentations, presentations_path, "path_presentations",
    "presentations_path"
  )
  presentations_site_subdir <- renamed_arg(
    subdir_presentations, presentations_site_subdir, "subdir_presentations",
    "presentations_site_subdir"
  )
  if (is.null(dirname_reports)) {
    dirname_reports <- list_books(path)
  }
  if (is.null(presentations)) {
    presentations <- list_presentations(presentations_path)
  }
  if (length(dirname_reports) == 0 && length(presentations) == 0) {
    stop("No Quarto book found in: ", path, call. = FALSE)
  }
  if (length(dirname_reports) > 0) check_dirnames(dirname_reports)
  if (length(presentations) > 0) check_dirnames(presentations)

  configs <- lapply(dirname_reports, function(d) {
    yml <- file.path(path, d, "_quarto.yml")
    if (file.exists(yml)) yaml::read_yaml(yml) else list()
  })
  titles <- if (is.null(titles)) {
    vapply(seq_along(dirname_reports), function(i) {
      title <- configs[[i]]$book$title
      if (is.null(title)) dirname_reports[[i]] else as.character(title)
    }, character(1))
  } else {
    resolve_titles(unlist(titles), dirname_reports)
  }
  titles <- unname(titles)
  category <- menu_category(
    dirname_reports, lapply(configs, function(x) x$category)
  )

  config <- list()
  if (file.exists(pkgdown_file)) {
    config <- yaml::read_yaml(pkgdown_file)
  }

  lang <- menu_lang(dirname_reports)

  # former components, one by language
  old <- paste0("reports_", c("en", "fr"))
  config$navbar$components[old] <- NULL
  if (length(config$navbar$components) == 0) {
    config$navbar$components <- NULL
  }
  config$navbar$structure$left <- setdiff(config$navbar$structure$left, old)

  if (length(dirname_reports) > 0) {
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
        file.path(site_subdir, dirname_reports, "index.html"),
        category = category,
        dirnames = dirname_reports
      )
    )
  }

  config <- set_presentations_menu(
    config, presentations, presentations_path, presentations_site_subdir,
    add_to_navbar
  )
  yaml::write_yaml(config, pkgdown_file)
  invisible(config)
}

# The navbar menu of the presentations (titles from the YAML header of the
# slides). Removed when there is no presentation.
set_presentations_menu <- function(config, presentations, path, site_subdir,
                                   add_to_navbar) {
  if (length(presentations) == 0) {
    config$navbar$components$presentations <- NULL
    if (length(config$navbar$components) == 0) {
      config$navbar$components <- NULL
    }
    config$navbar$structure$left <- setdiff(
      config$navbar$structure$left, "presentations"
    )
    return(config)
  }

  headers <- lapply(presentations, function(d) {
    file <- file.path(path, d, paste0(d, ".qmd"))
    tryCatch(read_slides(file)$header, error = function(e) list())
  })
  titles <- vapply(seq_along(presentations), function(i) {
    title <- headers[[i]]$title
    if (is.null(title)) presentations[[i]] else as.character(title)
  }, character(1))
  category <- menu_category(
    presentations, lapply(headers, function(x) x$category)
  )

  if (isTRUE(add_to_navbar)) {
    config$navbar$structure$left <- unique(c(
      config$navbar$structure$left,
      "presentations"
    ))
  }
  # headers by category and language, as the books
  config$navbar$components$presentations <- list(
    text = "Presentations",
    menu = reports_menu(
      menu_lang(presentations),
      unname(titles),
      file.path(site_subdir, presentations, "index.html"),
      category = category,
      dirnames = presentations
    )
  )
  config
}

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
#' @param render_presentations Whether to render the presentations. When one
#'   of `render_reports` and `render_presentations` is `TRUE`, the navbar is
#'   updated with every book and presentation found, rendered or not (the
#'   ones not rendered keep their previous output in the site).
#' @param path_presentations Folder containing the presentation folders (see
#'   [create_presentation()]). Without this folder, or without any
#'   presentation in it, there is no presentation on the site.
#' @param subdir_presentations Folder of the site where each presentation is
#'   rendered in its own sub-folder (`index.html`, and the PDF if the
#'   presentation has one).
#' @param build_readme Whether to rebuild the README with
#'   [devtools::build_readme()].
#' @param clean Whether to remove a book's previous output before rendering.
#' @param ... Other arguments passed to [pkgdown::build_site()].
#' @param path,site_subdir,presentations_path,presentations_subdir Deprecated,
#'   use `path_reports`, `subdir_reports`, `path_presentations` and
#'   `subdir_presentations`.
#' @param dest Deprecated, use `path_site`. With `dest`, the books and the
#'   presentations are rendered in `dest` (not in its `dev` folder) and
#'   pkgdown writes in the `destination` of `_pkgdown.yml`, as before.
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
                       ...,
                       path = NULL,
                       dest = NULL,
                       site_subdir = NULL,
                       presentations_path = NULL,
                       presentations_subdir = NULL) {
  path <- renamed_arg(path_reports, path, "path_reports", "path")
  site_subdir <- renamed_arg(
    subdir_reports, site_subdir, "subdir_reports", "site_subdir"
  )
  presentations_path <- renamed_arg(
    path_presentations, presentations_path, "path_presentations",
    "presentations_path"
  )
  presentations_subdir <- renamed_arg(
    subdir_presentations, presentations_subdir, "subdir_presentations",
    "presentations_subdir"
  )
  args <- list(...)
  if (is.null(dest)) {
    # pkgdown writes in `path_site`, or in `<path_site>/dev` for a
    # development version: the books and the presentations go there too
    args$override$destination <- args$override$destination %||% path_site
    dest <- pkgdown_dst_path(args$override)
  } else {
    dest <- renamed_arg(path_site, dest, "path_site", "dest")
  }
  for (pkg in c("pkgdown", if (build_readme) "devtools")) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      stop("Package '", pkg, "' is required.", call. = FALSE)
    }
  }
  if (build_readme) {
    devtools::build_readme()
  }
  if (render_reports || render_presentations) {
    # The navbar lists every book and presentation, also the ones not
    # rendered this time (their previous output stays in the site).
    books <- list_books(path)
    presentations <- list_presentations(presentations_path)
    if (length(books) == 0 && length(presentations) == 0) {
      stop("No Quarto book found in: ", path, call. = FALSE)
    }
    # init_site() creates the marker file that lets pkgdown recognise the
    # destination folder once the books are written into it.
    pkgdown_init_site(override = args$override %||% list())
    for (book in if (render_reports) books) {
      target <- file.path(dest, site_subdir, book)
      if (clean) unlink(target, recursive = TRUE)
      # The folder must exist for normalizePath() to return an absolute path
      # (otherwise Quarto resolves it relative to the book folder).
      dir.create(target, recursive = TRUE, showWarnings = FALSE)
      render_book(
        book,
        path_reports = path,
        output_dir = normalizePath(target, mustWork = FALSE)
      )
    }
    for (presentation in if (render_presentations) presentations) {
      target <- file.path(dest, presentations_subdir)
      if (clean) unlink(file.path(target, presentation), recursive = TRUE)
      dir.create(target, recursive = TRUE, showWarnings = FALSE)
      render_presentation(
        presentation,
        path_presentations = presentations_path,
        output_dir = normalizePath(target, mustWork = FALSE)
      )
    }
    update_pkgdown_yml(
      books,
      path_reports = path,
      subdir_reports = site_subdir,
      dirname_presentations = presentations,
      path_presentations = presentations_path,
      subdir_presentations = presentations_subdir
    )
  }
  invisible(do.call(pkgdown_build_site, args))
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

# The language of the books or presentations: the `_en`/`_fr` suffix of
# their folder name (or `-en`/`-fr`, former naming), "" without suffix.
menu_lang <- function(dirnames) {
  ifelse(
    grepl("[-_](fr|en)$", dirnames),
    sub(".*[-_](fr|en)$", "\\1", dirnames),
    ""
  )
}

# The category of the books or presentations: `package` when the folder name
# starts with a short number (`01_`, or `01-`), `others` otherwise, unless
# `values` (the `category` key of each one, possibly NULL) says otherwise.
menu_category <- function(dirnames, values = NULL) {
  category <- ifelse(
    grepl("^[0-9]{1,4}[-_]", dirnames), "package", "others"
  )
  for (i in seq_along(values)) {
    value <- values[[i]]
    if (is.null(value)) next
    value <- tolower(as.character(value)[[1]])
    if (!value %in% c("package", "others")) {
      stop(
        "The category must be 'package' or 'others', not '", value,
        "': ", dirnames[[i]],
        call. = FALSE
      )
    }
    category[[i]] <- value
  }
  unname(category)
}

# The order of the items of a category: by folder name for `package`; by date
# (folder name starting with `YYYYMMDD`), most recent first, then by folder
# name for `others`.
menu_order <- function(dirnames, category) {
  if (category == "package") {
    return(order(dirnames))
  }
  date <- ifelse(
    grepl("^[0-9]{8}", dirnames), substr(dirnames, 1, 8), ""
  )
  order(date == "", -rank(date), dirnames)
}

# The menu of the books or presentations: with both categories (`package`,
# `others`), a header by category, suffixed by the language when there are
# several; with a single category, a header by language when there are
# several languages (English, then French, then without language), none
# otherwise.
reports_menu <- function(lang, titles, hrefs, category = NULL,
                         dirnames = NULL) {
  if (is.null(category)) category <- rep("others", length(lang))
  if (is.null(dirnames)) dirnames <- as.character(seq_along(lang))
  items <- function(i) {
    i <- i[menu_order(dirnames[i], category[[i[[1]]]])]
    lapply(i, function(k) list(text = titles[[k]], href = hrefs[[k]]))
  }
  categories <- c(package = "Package", others = "Others")
  languages <- c(en = "English", fr = "Fran\u00e7ais")
  lang_order <- c("en", "fr", "")
  present_lang <- intersect(lang_order, unique(lang))
  present_cat <- intersect(names(categories), unique(category))

  groups <- list()
  if (length(present_cat) == 1) {
    if (length(present_lang) == 1) {
      return(items(seq_along(lang)))
    }
    for (l in present_lang) {
      header <- if (l == "") "Other" else languages[[l]]
      groups[[header]] <- which(lang == l)
    }
  } else {
    for (cat in present_cat) {
      for (l in present_lang) {
        i <- which(category == cat & lang == l)
        if (length(i) == 0) next
        header <- categories[[cat]]
        if (length(present_lang) > 1 && l != "") {
          header <- paste0(header, " [", l, "]")
        }
        groups[[header]] <- i
      }
    }
  }
  menu <- list()
  for (header in names(groups)) {
    if (length(menu) > 0) {
      menu <- c(menu, list(list(text = "---------")))
    }
    menu <- c(menu, list(list(text = header)), items(groups[[header]]))
  }
  menu
}
