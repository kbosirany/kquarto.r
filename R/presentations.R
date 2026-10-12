#' Create Quarto presentations
#'
#' Creates one folder per presentation in `path`, containing a single
#' `<name>.qmd` (reveal.js slides) and the files of the template (theme,
#' logos, ...). Presentations are independent of books: they have their own
#' templates (see [list_templates_presentation()]) and are rendered with
#' [render_presentation()].
#'
#' @param name Presentation folder names, created in `path`. The slides are
#'   written in `<name>/<name>.qmd`.
#' @param path Folder where the presentation folders are created.
#' @param title Presentation title. A character vector of the same length as
#'   `name`, or named by `name` to set only some titles. Defaults to `name`.
#' @param subtitle,author,date Values written in the YAML header of the
#'   slides. `NULL` leaves the template value.
#' @param lang Language of the presentation.
#' @param template Template used to initialise the slides: the name of a
#'   presentation template (see [list_templates_presentation()]), e.g.
#'   `"default-presentation"` or `"inrae-presentation"` (INRAE graphic
#'   charter), a template of another package (`"pkg::name"`) or the path to
#'   a template folder. Defaults to the option
#'   `kquarto.r.presentation.template`, or `"default-presentation"`.
#' @param overwrite Whether to replace the slides of an existing
#'   presentation.
#'
#' @return The paths of the `.qmd` files, invisibly.
#' @export
#'
#' @examples
#' tmp <- tempfile()
#' dir.create(tmp)
#' create_presentation(
#'   "seminaire",
#'   path = tmp,
#'   title = "Mon séminaire",
#'   author = "Kevin Orlando",
#'   template = "inrae-presentation"
#' )
#' list.files(tmp, recursive = TRUE)
create_presentation <- function(name,
                                path = ".",
                                title = NULL,
                                subtitle = NULL,
                                author = NULL,
                                date = NULL,
                                lang = "fr",
                                template = getOption(
                                  "kquarto.r.presentation.template",
                                  "default-presentation"
                                ),
                                overwrite = FALSE) {
  check_dirnames(name)
  if (!dir.exists(path)) {
    stop("`path` does not exist: ", path, call. = FALSE)
  }
  titles <- resolve_titles(title, name)
  template_path <- resolve_template(template, "presentation")
  template_qmd <- file.path(template_path, "slides.qmd")
  if (!file.exists(template_qmd)) {
    stop("The template has no `slides.qmd`: ", template_path, call. = FALSE)
  }

  dirs <- file.path(path, name)
  files <- file.path(dirs, paste0(name, ".qmd"))
  if (!overwrite && any(file.exists(files))) {
    stop(
      "Slides already exist for: ",
      paste(name[file.exists(files)], collapse = ", "),
      ". Use `overwrite = TRUE` to replace them.",
      call. = FALSE
    )
  }

  for (i in seq_along(dirs)) {
    dir.create(dirs[[i]], recursive = TRUE, showWarnings = FALSE)
    copy_dir(
      template_path, dirs[[i]],
      overwrite = overwrite, exclude = c("slides.qmd", "template.yml")
    )
    copy_shared(template_path, dirs[[i]], overwrite = overwrite)

    slides <- read_slides(template_qmd)
    slides$header$title <- titles[[i]]
    if (!is.null(subtitle)) slides$header$subtitle <- subtitle
    if (!is.null(author)) slides$header$author <- author
    if (!is.null(date)) slides$header$date <- date
    if (!is.null(lang)) slides$header$lang <- lang
    write_slides(slides, files[[i]])
    add_lines(file.path(dirs[[i]], ".gitignore"), "/.quarto/")
  }
  invisible(files)
}

#' List the presentations of a folder
#'
#' A presentation is a folder `<name>/` containing a `<name>.qmd` whose
#' format is `revealjs`.
#'
#' @param path Folder containing the presentation folders.
#'
#' @return The names of the presentation folders.
#' @export
#'
#' @examples
#' tmp <- tempfile()
#' dir.create(tmp)
#' create_presentation("seminaire", path = tmp)
#' list_presentations(tmp)
list_presentations <- function(path = ".") {
  dirs <- list.dirs(path, full.names = FALSE, recursive = FALSE)
  dirs <- dirs[file.exists(file.path(path, dirs, paste0(dirs, ".qmd")))]
  is_slides <- vapply(dirs, function(d) {
    file <- file.path(path, d, paste0(d, ".qmd"))
    header <- tryCatch(read_slides(file)$header, error = function(e) list())
    "revealjs" %in% c(names(header$format), unlist(header$format))
  }, logical(1))
  unname(dirs[is_slides])
}

#' Render Quarto presentations
#'
#' Calls [quarto::quarto_render()] on the slides of each presentation. The
#' HTML file is written next to the `.qmd`.
#'
#' @param name Presentation folder names, relative to `path`. By default,
#'   every presentation found in `path` (see [list_presentations()]).
#' @param path Folder containing the presentation folders.
#' @param output_format Output format passed to Quarto, e.g. `"revealjs"` or
#'   `"pdf"`. `NULL` renders the formats of the slides.
#' @param quiet Whether to suppress Quarto output.
#' @param ... Other arguments passed to [quarto::quarto_render()].
#'
#' @return The paths of the rendered HTML files, invisibly.
#' @export
#'
#' @examples
#' \dontrun{
#' create_presentation("seminaire")
#' render_presentation("seminaire")
#' }
render_presentation <- function(name = NULL,
                                path = ".",
                                output_format = NULL,
                                quiet = FALSE,
                                ...) {
  if (is.null(name)) {
    name <- list_presentations(path)
    if (length(name) == 0) {
      stop("No Quarto presentation found in: ", path, call. = FALSE)
    }
  }
  check_dirnames(name)
  files <- file.path(path, name, paste0(name, ".qmd"))
  missing <- !file.exists(files)
  if (any(missing)) {
    stop(
      "No slides in: ", paste(name[missing], collapse = ", "),
      ". Create the presentation with `create_presentation()` first.",
      call. = FALSE
    )
  }
  if (is.null(quarto_bin())) {
    stop(
      "The Quarto CLI was not found. Install it from https://quarto.org.",
      call. = FALSE
    )
  }
  for (file in files) {
    quarto_render(
      input = normalizePath(file),
      output_format = output_format,
      quiet = quiet,
      ...
    )
  }
  invisible(sub("\\.qmd$", ".html", files))
}

# Slides = YAML header + body. Only the header is rewritten.
read_slides <- function(file) {
  lines <- readLines(file, warn = FALSE, encoding = "UTF-8")
  delim <- which(lines == "---")
  if (length(delim) < 2 || delim[[1]] != 1) {
    stop("The slides have no YAML header: ", file, call. = FALSE)
  }
  header <- yaml::yaml.load(paste(lines[2:(delim[[2]] - 1)], collapse = "\n"))
  list(header = header, body = lines[-seq_len(delim[[2]])])
}

write_slides <- function(slides, file) {
  handlers <- list(logical = function(x) {
    value <- ifelse(x, "true", "false")
    class(value) <- "verbatim"
    value
  })
  header <- yaml::as.yaml(slides$header, handlers = handlers)
  writeLines(c("---", sub("\n$", "", header), "---", slides$body), file,
             useBytes = TRUE)
}
