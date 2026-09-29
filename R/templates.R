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
  check_template_name(name)
  from_path <- resolve_template(from)
  target <- file.path(dir, name)
  if (dir.exists(target)) {
    if (!overwrite) {
      stop(
        "Template '", name, "' already exists. Use `overwrite = TRUE` to replace it.",
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
    exclude = c("_book", ".quarto", "_freeze", ".gitignore")
  )
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
#' A package such as `kquarto.r.inrae` can also make its template the
#' default, either by wrapping the functions:
#'
#' ```r
#' create_book <- function(dirname_reports, ..., template = "kquarto.r.inrae::inrae") {
#'   kquarto.r::create_book(dirname_reports, ..., template = template)
#' }
#' ```
#'
#' or by setting the option `kquarto.r.template` (e.g. in its `.onLoad()` or
#' in a user's `.Rprofile`): `options(kquarto.r.template = "kquarto.r.inrae::inrae")`.
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
  user <- template_folders(template_dir())
  package <- template_folders(system.file("templates", package = "kquarto.r"))
  templates <- data.frame(
    name = c(basename(user), basename(package)),
    source = c(rep("user", length(user)), rep("package", length(package))),
    path = c(user, package),
    stringsAsFactors = FALSE
  )
  for (pkg in packages) {
    folders <- template_folders(system.file("templates", package = pkg))
    templates <- rbind(templates, data.frame(
      name = paste0(pkg, "::", basename(folders)),
      source = rep(pkg, length(folders)),
      path = folders,
      stringsAsFactors = FALSE
    ))
  }
  templates
}

#' Remove a user book template
#'
#' @param name Template name.
#'
#' @return `TRUE` invisibly if the template was removed.
#' @export
remove_template_book <- function(name) {
  check_template_name(name)
  target <- file.path(template_dir(), name)
  if (!dir.exists(target)) {
    stop("No user template named '", name, "'.", call. = FALSE)
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

resolve_template <- function(template) {
  if (!is.character(template) || length(template) != 1 || is.na(template)) {
    stop("`template` must be a single string.", call. = FALSE)
  }
  if (dir.exists(template)) {
    if (!file.exists(file.path(template, "_quarto.yml"))) {
      stop("The template folder must contain a `_quarto.yml`: ", template, call. = FALSE)
    }
    return(normalizePath(template))
  }
  if (grepl("::", template, fixed = TRUE)) {
    parts <- strsplit(template, "::", fixed = TRUE)[[1]]
    if (length(parts) != 2 || !requireNamespace(parts[[1]], quietly = TRUE)) {
      stop("Package '", parts[[1]], "' of template '", template, "' is not installed.",
           call. = FALSE)
    }
    path <- system.file("templates", parts[[2]], package = parts[[1]])
    if (!nzchar(path) || !file.exists(file.path(path, "_quarto.yml"))) {
      stop("Package '", parts[[1]], "' has no template '", parts[[2]], "'.", call. = FALSE)
    }
    return(path)
  }
  templates <- list_templates_book()
  match <- templates$path[templates$name == template]
  if (length(match) == 0) {
    stop(
      "Unknown template '", template, "'. Available templates: ",
      paste(unique(templates$name), collapse = ", "),
      call. = FALSE
    )
  }
  match[[1]]
}

template_folders <- function(dir) {
  if (!nzchar(dir) || !dir.exists(dir)) {
    return(character())
  }
  folders <- list.dirs(dir, full.names = TRUE, recursive = FALSE)
  folders[file.exists(file.path(folders, "_quarto.yml"))]
}

check_template_name <- function(name) {
  if (!is.character(name) || length(name) != 1 || is.na(name) ||
      !grepl("^[A-Za-z0-9._-]+$", name)) {
    stop(
      "`name` must be a single string made of letters, digits, '.', '_' or '-'.",
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
