#' Render one book or presentation in the folder of the pkgdown site
#'
#' Renders `item` where [build_site()] would render it: a book in
#' `<site>/<subdir_reports>/<book>/`, a presentation in
#' `<site>/<subdir_presentations>/<name>/`. It is meant for a CI job that
#' renders each book and presentation on its own, at the same time as the
#' others (see [update_gitlab_ci()]). A last job then builds the site with
#' `build_site(render_reports = FALSE, render_presentations = FALSE,
#' check_rendered = TRUE)`.
#'
#' The HTML is always rendered, like in [build_site()], and so are the
#' formats of `output_format` that the item declares. The site of a
#' development version (pkgdown `development: mode`, or the environment
#' variable `PKGDOWN_DEV_MODE`) is `<path_site>/dev`.
#'
#' @param item Folder of the book or presentation, e.g.
#'   `"reports/01_first_fr"` or `"presentations/seminar"`. An item that does
#'   not exist is skipped with a message: the matrix of the CI lists the
#'   items of several branches, see [update_gitlab_ci()].
#' @param path_site Folder of the pkgdown site, see [build_site()].
#' @param path_reports,path_presentations Folders containing the books and
#'   the presentations.
#' @param subdir_reports,subdir_presentations Folders of the site where each
#'   book and presentation is rendered in its own sub-folder.
#' @param output_format Formats rendered in addition to the HTML, see
#'   [build_site()] (each format runs the code of the chapters again).
#' @param clean Whether to remove the previous output of the item in the
#'   site before rendering.
#'
#' @return The folder of the item in the site, invisibly (`NULL` if the item
#'   does not exist).
#' @export
#'
#' @examples
#' \dontrun{
#' render_site_item("reports/01_first_fr")
#' }
render_site_item <- function(item,
                             path_site = "public",
                             path_reports = "reports",
                             path_presentations = "presentations",
                             subdir_reports = "reports",
                             subdir_presentations = "presentations",
                             output_format = NULL,
                             clean = TRUE) {
  if (!is.character(item) || length(item) != 1 || is.na(item)) {
    stop("`item` must be the folder of one book or presentation.",
         call. = FALSE)
  }
  item <- sub("/+$", "", item)
  name <- basename(item)
  parent <- sub("/+$", "", dirname(item))
  type <- if (identical(parent, sub("/+$", "", path_reports))) {
    "book"
  } else if (identical(parent, sub("/+$", "", path_presentations))) {
    "presentation"
  } else {
    stop(
      "Not in `", path_reports, "` or `", path_presentations, "`: ", item,
      call. = FALSE
    )
  }
  if (!dir.exists(item)) {
    message("Not on this branch, nothing to render: ", item)
    return(invisible(NULL))
  }

  dest <- pkgdown_dst_path(list(destination = path_site))
  target <- file.path(
    dest, if (type == "book") subdir_reports else subdir_presentations, name
  )
  if (clean) unlink(target, recursive = TRUE)
  # The folder must exist for normalizePath() to return an absolute path
  # (otherwise Quarto resolves it relative to the book folder).
  dir.create(target, recursive = TRUE, showWarnings = FALSE)
  target <- normalizePath(target)

  passes <- item_passes(
    type, name, if (type == "book") path_reports else path_presentations,
    if (type == "book") target, output_format
  )
  run_renders(passes$main)
  for (format in extra_formats(output_format)) {
    if (!is.null(passes[[format]])) run_renders(passes[[format]])
  }
  if (type == "presentation") {
    # the slides are written next to the `.qmd`
    copy_presentation_outputs(name, item, dirname(target))
  }
  invisible(target)
}

# The additional formats of `output_format`: not the HTML, that is always
# rendered, and none with "all", that renders every format of the item.
extra_formats <- function(output_format) {
  if ("all" %in% output_format) {
    return(character())
  }
  setdiff(output_format, c("html", "revealjs"))
}

# The renders of an item of the site (a `type` "book" or "presentation"), by
# pass: `main`, the HTML (or every format with "all"), then one pass by
# additional format that the item declares. A book is rendered in
# `output_dir` (the folder of the site, outside the folder of the book:
# the formats do not remove each other there).
item_passes <- function(type, name, path, output_dir = NULL,
                        output_format = NULL) {
  declared <- if (type == "book") {
    book_formats(path, name)
  } else {
    presentation_formats(path, name)
  }
  render <- function(format) {
    if (type == "book") {
      book_renders(name, path, output_dir, output_format = format)
    } else {
      presentation_renders(name, path, output_format = format)
    }
  }
  main <- if ("all" %in% output_format) {
    "all"
  } else {
    main_format(declared, if (type == "book") "html" else "revealjs")
  }
  extra <- intersect(extra_formats(output_format), declared)
  passes <- c(list(main = render(main)), lapply(extra, render))
  names(passes) <- c("main", extra)
  passes
}
