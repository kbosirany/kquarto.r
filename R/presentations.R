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
#' @param formats Formats of the slides. `NULL` keeps those of the
#'   template (`"revealjs"`, HTML). Add `"beamer"` to get a PDF made with
#'   LaTeX (needs a LaTeX distribution, e.g. `quarto install tinytex`),
#'   rendered with `render_presentation(output_format = "beamer")`.
#'   Typst is not available: Quarto has no Typst slides.
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
                                formats = NULL,
                                overwrite = FALSE) {
  check_dirnames(name)
  check_presentation_formats(formats)
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
      overwrite = overwrite,
      exclude = c("slides.qmd", "template.yml", "beamer.yml")
    )
    copy_shared(template_path, dirs[[i]], overwrite = overwrite)

    slides <- read_slides(template_qmd)
    slides$header$title <- titles[[i]]
    if (!is.null(subtitle)) slides$header$subtitle <- subtitle
    if (!is.null(author)) slides$header$author <- author
    if (!is.null(date)) slides$header$date <- date
    if (!is.null(lang)) slides$header$lang <- lang
    slides$header$format <- set_presentation_formats(
      slides$header$format, formats, template_path
    )
    write_slides(slides, files[[i]])
    add_lines(file.path(dirs[[i]], ".gitignore"), "/.quarto/")
  }
  invisible(files)
}

check_presentation_formats <- function(formats) {
  if (is.null(formats)) {
    return(invisible(TRUE))
  }
  if (!is.character(formats) || anyNA(formats) ||
      !all(formats %in% c("revealjs", "beamer"))) {
    stop(
      "`formats` must be a subset of \"revealjs\" and \"beamer\" ",
      "(Typst has no slides in Quarto).",
      call. = FALSE
    )
  }
  invisible(TRUE)
}

# `beamer.yml` of the template gives the beamer options; the default is a
# 16:9 slide deck.
set_presentation_formats <- function(format, formats, template_path) {
  if (is.null(formats)) {
    return(format)
  }
  if (!"revealjs" %in% formats) format$revealjs <- NULL
  if ("beamer" %in% formats) {
    file <- file.path(template_path, "beamer.yml")
    format$beamer <- if (file.exists(file)) {
      yaml::read_yaml(file)
    } else {
      list(aspectratio = 169L)
    }
  }
  format
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
#' @param output_format Output format passed to Quarto, e.g. `"revealjs"`,
#'   `"beamer"` (PDF, see the `formats` argument of
#'   [create_presentation()]) or `"pptx"` (PowerPoint: add a `pptx:` format
#'   with a `reference-doc` to the YAML header of the slides to use the
#'   masks of a PowerPoint template). `NULL` renders the formats of the
#'   slides.
#' @param quiet Whether to suppress Quarto output.
#' @param output_dir Folder where the rendered files are copied, in a
#'   sub-folder per presentation (`<output_dir>/<name>/`): the HTML slides
#'   as `index.html` and the PDF and PowerPoint files, if there are some, as
#'   `<name>.pdf` and `<name>.pptx`. `NULL`
#'   leaves the files next to the `.qmd`. Used by [build_site()].
#' @param ... Other arguments passed to [quarto::quarto_render()].
#'
#' @return The paths of the rendered files (`.html`, `.pdf` for
#'   `output_format = "beamer"` or `.pptx` for `output_format = "pptx"`),
#'   invisibly.
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
                                output_dir = NULL,
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
  ext <- switch(
    if (is.null(output_format)) "revealjs" else output_format,
    beamer = ".pdf",
    pptx = ".pptx",
    ".html"
  )
  rendered <- sub("\\.qmd$", ext, files)
  if (!is.null(output_dir)) {
    copy_presentation_outputs(name, file.path(path, name), output_dir)
  }
  invisible(rendered)
}

# Copies the rendered slides of presentation folders to
# `<output_dir>/<name>/`: `index.html`, and the PDF when there is one.
copy_presentation_outputs <- function(name, dirs, output_dir) {
  for (i in seq_along(name)) {
    target <- file.path(output_dir, name[[i]])
    dir.create(target, recursive = TRUE, showWarnings = FALSE)
    html <- file.path(dirs[[i]], paste0(name[[i]], ".html"))
    pdf <- file.path(dirs[[i]], paste0(name[[i]], ".pdf"))
    pptx <- file.path(dirs[[i]], paste0(name[[i]], ".pptx"))
    if (!any(file.exists(c(html, pdf, pptx)))) {
      stop("No rendered slides for: ", name[[i]], call. = FALSE)
    }
    if (file.exists(html)) {
      file.copy(html, file.path(target, "index.html"), overwrite = TRUE)
    }
    for (file in c(pdf, pptx)) {
      if (file.exists(file)) {
        file.copy(file, file.path(target, basename(file)), overwrite = TRUE)
      }
    }
  }
  invisible(output_dir)
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
