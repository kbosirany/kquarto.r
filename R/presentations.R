#' Create Quarto presentations
#'
#' Creates one folder per presentation in `path_presentations`, containing a
#' single
#' `<name>.qmd` (reveal.js slides) and the files of the template (theme,
#' logos, ...). Presentations are independent of books: they have their own
#' templates (see [list_templates_presentation()]) and are rendered with
#' [render_presentation()].
#'
#' @param dirname_presentations Presentation folder names, created in
#'   `path_presentations`. The slides are
#'   written in `<name>/<name>.qmd`.
#' @param path_presentations Folder where the presentation folders are
#'   created.
#' @param title Presentation title. A character vector of the same length as
#'   `dirname_presentations`, or named by `dirname_presentations` to set
#'   only some titles. Defaults to `dirname_presentations`.
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
#' @param name,path Deprecated, use `dirname_presentations` and
#'   `path_presentations`.
#'
#' @return The paths of the `.qmd` files, invisibly.
#' @export
#'
#' @examples
#' tmp <- tempfile()
#' dir.create(tmp)
#' create_presentation(
#'   "seminaire",
#'   path_presentations = tmp,
#'   title = "Mon séminaire",
#'   author = "Kevin Orlando",
#'   template = "inrae-presentation"
#' )
#' list.files(tmp, recursive = TRUE)
create_presentation <- function(dirname_presentations,
                                path_presentations = "presentations",
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
                                overwrite = FALSE,
                                name = NULL,
                                path = NULL) {
  name <- renamed_arg(
    if (missing(dirname_presentations)) NULL else dirname_presentations,
    name, "dirname_presentations", "name"
  )
  path <- renamed_arg(
    path_presentations, path, "path_presentations", "path"
  )
  check_dirnames(name)
  check_presentation_formats(formats)
  if (!dir.exists(path)) {
    stop("`path_presentations` does not exist: ", path, call. = FALSE)
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
#' @param path_presentations Folder containing the presentation folders.
#' @param path Deprecated, use `path_presentations`.
#'
#' @return The names of the presentation folders.
#' @export
#'
#' @examples
#' tmp <- tempfile()
#' dir.create(tmp)
#' create_presentation("seminaire", path_presentations = tmp)
#' list_presentations(tmp)
list_presentations <- function(path_presentations = "presentations",
                               path = NULL) {
  path <- renamed_arg(
    path_presentations, path, "path_presentations", "path"
  )
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
#' @param dirname_presentations Presentation folder names, relative to
#'   `path_presentations`. By default, every presentation found in
#'   `path_presentations` (see [list_presentations()]).
#' @param path_presentations Folder containing the presentation folders.
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
#' @param workers Number of presentations rendered at the same time, see
#'   [render_book()].
#' @param name,path Deprecated, use `dirname_presentations` and
#'   `path_presentations`.
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
render_presentation <- function(dirname_presentations = NULL,
                                path_presentations = "presentations",
                                output_format = NULL,
                                quiet = FALSE,
                                output_dir = NULL,
                                ...,
                                workers = getOption("kquarto.r.workers", 1L),
                                name = NULL,
                                path = NULL) {
  name <- renamed_arg(
    dirname_presentations, name, "dirname_presentations", "name"
  )
  path <- renamed_arg(
    path_presentations, path, "path_presentations", "path"
  )
  renders <- presentation_renders(name, path, output_format, quiet, ...)
  run_renders(renders, workers)
  if (!is.null(output_dir)) {
    name <- vapply(renders, function(x) x$label, character(1))
    copy_presentation_outputs(name, file.path(path, name), output_dir)
  }
  invisible(vapply(renders, function(x) x$output, character(1)))
}

# The renders of presentations, as book_renders(): `output` is the rendered
# file, next to the `.qmd`.
presentation_renders <- function(name, path, output_format = NULL,
                                 quiet = FALSE, ...) {
  if (is.null(name)) {
    name <- list_presentations(path)
    if (length(name) == 0) {
      stop(
        "No Quarto presentation found in: ", path, call. = FALSE
      )
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
  ext <- switch(
    if (is.null(output_format)) "revealjs" else output_format,
    beamer = ".pdf",
    pptx = ".pptx",
    ".html"
  )
  lapply(seq_along(files), function(i) {
    list(
      label = name[[i]],
      args = list(
        input = normalizePath(files[[i]]),
        output_format = output_format,
        quiet = quiet,
        ...
      ),
      output = sub("\\.qmd$", ext, files[[i]])
    )
  })
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
