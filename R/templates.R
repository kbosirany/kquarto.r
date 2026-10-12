#' Create a reusable book template
#'
#' Saves a template that can then be used with
#' `create_book(template = name)`. A template is a folder containing at least
#' a `_quarto.yml`, plus any file to copy into new reports (chapters,
#' `references.bib`, `styles.css`, logos, ...).
#'
#' Templates are stored in [template_dir()], i.e. the user data folder of
#' the package by default, so they are available from every project. Set
#' the option `kquarto.r.template_dir` to share templates via another folder
#' (e.g. a folder under version control).
#'
#' To ship templates in your own package (e.g. an institutional charter),
#' create them with `dir = "inst/templates"` in that package; they are then
#' available as `create_book(template = "pkg::name")`. See the
#' "Templates from another package" section of [list_templates_book()].
#'
#' @param name Template name.
#' @param from Where the template files come from: the name of an existing
#'   template (by default the one shipped with the package) or the path to a
#'   folder, typically a report you already set up. Rendering outputs
#'   (`_book/`, `.quarto/`, `_freeze/`) are not copied.
#' @param overwrite Whether to replace an existing template with the same
#'   name.
#' @param dir Folder where the template is saved. Defaults to
#'   [template_dir()]; use `"inst/templates"` from the root of a package
#'   that ships templates.
#'
#' @return The path of the template folder, invisibly. Edit its files to
#'   customise the template.
#' @export
#'
#' @examples
#' old <- options(kquarto.r.template_dir = tempfile())
#' path <- create_template_book("mon_template")
#' list.files(path)
#' list_templates_book()
#' options(old)
create_template_book <- function(name, from = "default", overwrite = FALSE,
                                 dir = template_dir()) {
  create_template(name, from, "book", overwrite, dir)
}

create_template <- function(name, from, type, overwrite, dir) {
  check_template_name(name)
  from_path <- resolve_template(from, type)
  target <- file.path(dir, name)
  if (dir.exists(target)) {
    if (!overwrite) {
      stop(
        "Template '", name, "' already exists. ",
        "Use `overwrite = TRUE` to replace it.",
        call. = FALSE
      )
    }
    unlink(target, recursive = TRUE)
  }
  dir.create(target, recursive = TRUE, showWarnings = FALSE)
  copy_dir(
    from_path,
    target,
    overwrite = TRUE,
    exclude = c("_book", ".quarto", "_freeze", ".gitignore", "template.yml")
  )
  # A saved template is self-contained: shared files are copied into it.
  copy_shared(from_path, target, overwrite = TRUE)
  yaml::write_yaml(list(type = type), file.path(target, "template.yml"))
  message("Template '", name, "' created in: ", target)
  invisible(normalizePath(target))
}

#' List the available book templates
#'
#' @section Templates from another package:
#' Any package can ship templates in `inst/templates/<name>/` (each folder
#' containing a `_quarto.yml`). They are used with
#' `create_book(template = "pkg::name")`.
#'
#' Such a package can also make its template the default, either by
#' wrapping the functions:
#'
#' ```r
#' create_book <- function(dirname_reports, ...,
#'                         template = "monpkg::charte") {
#'   kquarto.r::create_book(dirname_reports, ..., template = template)
#' }
#' ```
#'
#' or by setting the option `kquarto.r.template` (e.g. in its `.onLoad()` or
#' in a user's `.Rprofile`):
#' `options(kquarto.r.template = "monpkg::charte")`.
#'
#' @param packages Names of other packages whose templates are listed too.
#'
#' @return A data frame with the template `name`, its `source` (`"user"`,
#'   `"package"` for the templates of kquarto.r, or the name of another
#'   package) and its `path`. A user template with the same name as a
#'   kquarto.r template takes precedence over it. Templates of other
#'   packages are named `"pkg::name"`.
#' @export
#'
#' @examples
#' list_templates_book()
list_templates_book <- function(packages = NULL) {
  list_templates("book", packages)
}

list_templates <- function(type, packages = NULL) {
  user <- template_folders(template_dir(), type)
  package <- template_folders(
    system.file("templates", package = "kquarto.r"), type
  )
  templates <- data.frame(
    name = c(basename(user), basename(package)),
    source = c(rep("user", length(user)), rep("package", length(package))),
    path = c(user, package),
    stringsAsFactors = FALSE
  )
  for (pkg in packages) {
    folders <- template_folders(system.file("templates", package = pkg), type)
    templates <- rbind(templates, data.frame(
      name = paste0(pkg, "::", basename(folders)),
      source = rep(pkg, length(folders)),
      path = folders,
      stringsAsFactors = FALSE
    ))
  }
  templates
}

#' Manage presentation templates
#'
#' Presentation templates live in the same folders as book templates (see
#' [template_dir()]), but a `template.yml` declares their `type`, so
#' [list_templates_book()] and `list_templates_presentation()` never mix.
#' A presentation template is a folder with a `template.yml`
#' (`type: presentation`), a `slides.qmd` (reveal.js slides with a YAML
#' header) and any file it needs (theme, logos, ...). A template can reuse
#' the files of a shared charter with `shared: <name>` in its `template.yml`
#' (folder `shared/<name>/` next to `templates/` in the package): they are
#' copied into each presentation, and into user templates created from it.
#'
#' @inheritParams create_template_book
#' @param from Where the template files come from: the name of an existing
#'   presentation template (by default the one shipped with the package) or
#'   the path to a folder, typically a presentation you already set up.
#' @param packages Names of other packages whose templates are listed too.
#'
#' @return `create_template_presentation()` returns the path of the template
#'   folder, invisibly. `list_templates_presentation()` returns a data frame
#'   with the template `name`, its `source` and its `path`.
#'   `remove_template_presentation()` returns `TRUE` invisibly.
#' @export
#'
#' @examples
#' old <- options(kquarto.r.template_dir = tempfile())
#' list_templates_presentation()
#' create_template_presentation("ma_charte", from = "inrae-presentation")
#' options(old)
create_template_presentation <- function(name,
                                         from = "default-presentation",
                                         overwrite = FALSE,
                                         dir = template_dir()) {
  create_template(name, from, "presentation", overwrite, dir)
}

#' @rdname create_template_presentation
#' @export
list_templates_presentation <- function(packages = NULL) {
  list_templates("presentation", packages)
}

#' @rdname create_template_presentation
#' @export
remove_template_presentation <- function(name) {
  remove_template(name, "presentation")
}

#' Remove a user book template
#'
#' @param name Template name.
#'
#' @return `TRUE` invisibly if the template was removed.
#' @export
remove_template_book <- function(name) {
  remove_template(name, "book")
}

remove_template <- function(name, type) {
  check_template_name(name)
  target <- file.path(template_dir(), name)
  if (!dir.exists(target) || !is_template_folder(target, type)) {
    stop(
      "No user template named '", name, "' of type '", type, "'.",
      call. = FALSE
    )
  }
  unlink(target, recursive = TRUE)
  invisible(TRUE)
}

#' Folder where user templates are stored
#'
#' Returns the option `kquarto.r.template_dir` if set, otherwise
#' `tools::R_user_dir("kquarto.r", "data")/templates`.
#'
#' @return A path.
#' @export
#'
#' @examples
#' template_dir()
template_dir <- function() {
  getOption(
    "kquarto.r.template_dir",
    file.path(tools::R_user_dir("kquarto.r", which = "data"), "templates")
  )
}

resolve_template <- function(template, type = "book") {
  if (!is.character(template) || length(template) != 1 || is.na(template)) {
    stop("`template` must be a single string.", call. = FALSE)
  }
  if (dir.exists(template)) {
    check_template_folder(template, type)
    return(normalizePath(template))
  }
  if (grepl("::", template, fixed = TRUE)) {
    parts <- strsplit(template, "::", fixed = TRUE)[[1]]
    if (length(parts) != 2 || !requireNamespace(parts[[1]], quietly = TRUE)) {
      stop(
        "Package '", parts[[1]], "' of template '", template,
        "' is not installed.",
        call. = FALSE
      )
    }
    path <- system.file("templates", parts[[2]], package = parts[[1]])
    if (!nzchar(path) || !is_template_folder(path, type)) {
      stop(
        "Package '", parts[[1]], "' has no template '", parts[[2]],
        "' of type '", type, "'.",
        call. = FALSE
      )
    }
    return(path)
  }
  templates <- list_templates(type)
  match <- templates$path[templates$name == template]
  if (length(match) == 0) {
    stop(
      "Unknown template '", template, "' of type '", type,
      "'. Available templates: ",
      paste(unique(templates$name), collapse = ", "),
      call. = FALSE
    )
  }
  match[[1]]
}

# A template folder has a type: "book" (a `_quarto.yml`, `template.yml`
# optional) or "presentation" (a `template.yml` declaring the type).
template_info <- function(path) {
  file <- file.path(path, "template.yml")
  info <- if (file.exists(file)) yaml::read_yaml(file) else list()
  if (is.null(info)) info <- list()
  info$type <- info$type %||% "book"
  info
}

is_template_folder <- function(path, type) {
  if (type == "book") {
    return(file.exists(file.path(path, "_quarto.yml")) &&
             template_info(path)$type == "book")
  }
  file.exists(file.path(path, "template.yml")) &&
    template_info(path)$type == type
}

check_template_folder <- function(path, type) {
  if (!is_template_folder(path, type)) {
    stop(
      "The template folder must be a ", type, " template (",
      if (type == "book") "a `_quarto.yml`" else
        paste0("a `template.yml` with `type: ", type, "`"),
      "): ", path,
      call. = FALSE
    )
  }
  invisible(TRUE)
}

template_folders <- function(dir, type = "book") {
  if (!nzchar(dir) || !dir.exists(dir)) {
    return(character())
  }
  folders <- list.dirs(dir, full.names = TRUE, recursive = FALSE)
  folders <- folders[vapply(folders, is_template_folder, logical(1), type)]
  normalizePath(folders)
}

# Files shared between templates (e.g. a graphic charter) live in
# `shared/<name>/`, next to the `templates/` folder of the package.
copy_shared <- function(template_path, to, overwrite = FALSE) {
  shared <- template_info(template_path)$shared
  if (is.null(shared)) {
    return(invisible(character()))
  }
  from <- file.path(dirname(dirname(template_path)), "shared", shared)
  if (!dir.exists(from)) {
    stop("Shared files '", shared, "' not found: ", from, call. = FALSE)
  }
  copy_dir(from, to, overwrite = overwrite)
}

check_template_name <- function(name) {
  if (!is.character(name) || length(name) != 1 || is.na(name) ||
      !grepl("^[A-Za-z0-9._-]+$", name)) {
    stop(
      "`name` must be a single string made of letters, digits, ",
      "'.', '_' or '-'.",
      call. = FALSE
    )
  }
  invisible(TRUE)
}

copy_dir <- function(from, to, overwrite = FALSE, exclude = character()) {
  files <- list.files(from, recursive = TRUE, all.files = TRUE, no.. = TRUE)
  top <- sub("/.*$", "", files)
  files <- files[!top %in% exclude]
  for (file in files) {
    dest <- file.path(to, file)
    dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)
    file.copy(file.path(from, file), dest, overwrite = overwrite)
  }
  invisible(files)
}
