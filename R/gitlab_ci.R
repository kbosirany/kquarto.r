#' Update the list of books and presentations in the GitLab CI
#'
#' Rewrites the list of the matrix of the job that renders each book and
#' presentation in its own job, in `.gitlab-ci.yml`:
#'
#' ```
#' render:
#'   parallel:
#'     matrix:
#'       - ITEM:
#'           - reports/01_first_fr
#'           - presentations/seminar
#' ```
#'
#' Only the lines of the items are replaced: the rest of the file, comments
#' included, is kept. The items can be listed on several lines (`- item`) or
#' on the line of the variable (`- ITEM: [a, b]`); the result is always the
#' former. The list has the books and presentations of the
#' working directory and of the branches `refs` (read with git, without
#' checking them out), so that a job of the matrix exists for the items of
#' every branch built by the CI: a job whose item is not on its branch has
#' nothing to render.
#'
#' @param path_ci Path to the GitLab CI file.
#' @param path_reports Folder containing the book folders.
#' @param path_presentations Folder containing the presentation folders.
#' @param refs Git branches whose books and presentations are added to those
#'   of the working directory. A branch that does not exist is ignored (run
#'   `git fetch` to update the remote ones).
#' @param variable Name of the variable of the matrix that has the items.
#' @param fetch Whether to run `git fetch origin` first, so that the remote
#'   branches of `refs` are up to date.
#'
#' @return The items of the list (`reports/<book>` and
#'   `presentations/<name>`), invisibly.
#' @export
#'
#' @examples
#' \dontrun{
#' update_gitlab_ci()
#' }
update_gitlab_ci <- function(path_ci = ".gitlab-ci.yml",
                             path_reports = "reports",
                             path_presentations = "presentations",
                             refs = c("origin/main", "origin/dev"),
                             variable = "ITEM",
                             fetch = FALSE) {
  if (!file.exists(path_ci)) {
    stop("No such file: ", path_ci, call. = FALSE)
  }
  if (fetch) {
    git_fetch()
  }
  items <- c(
    file.path(path_reports, list_books(path_reports)),
    file.path(path_presentations, list_presentations(path_presentations))
  )
  for (ref in refs) {
    items <- c(items, git_items(ref, path_reports, path_presentations))
  }
  items <- unique(items)
  if (length(items) == 0) {
    message("No book or presentation found, ", path_ci, " not changed.")
    return(invisible(items))
  }
  # books, then presentations; each one sorted by name
  is_pres <- startsWith(items, paste0(path_presentations, "/"))
  items <- c(sort(items[!is_pres]), sort(items[is_pres]))

  lines <- readLines(path_ci, warn = FALSE)
  writeLines(replace_matrix_items(lines, items, variable, path_ci), path_ci)
  message(
    path_ci, " updated: ", length(items), " item(s) in the matrix."
  )
  invisible(items)
}

# `lines` of the CI file with the items of the matrix `- <variable>:`
# replaced by `items`, with the indentation of the previous ones.
replace_matrix_items <- function(lines, items, variable, path_ci) {
  start <- grep(
    sprintf("^\\s*- %s:\\s*(\\[.*\\])?\\s*(#.*)?$", variable), lines
  )
  if (length(start) != 1) {
    stop(
      "Expected one `- ", variable, ":` line in ", path_ci, ", found ",
      length(start), ". Add the matrix to the job first:\n",
      "  parallel:\n    matrix:\n      - ", variable, ":\n",
      "          - reports/<book>",
      call. = FALSE
    )
  }
  # the items on the line of the variable: `- ITEM: [a, b]`
  if (grepl("\\[.*\\]", lines[[start]])) {
    lines[[start]] <- sub("^(\\s*- [^:]+:).*$", "\\1", lines[[start]])
  }
  # the list items follow (blank lines and comments in between are kept)
  is_item <- grepl("^\\s*- \\S+\\s*$", lines)
  end <- start
  while (end < length(lines) && (
    is_item[[end + 1]] || grepl("^\\s*(#.*)?$", lines[[end + 1]])
  )) {
    end <- end + 1
  }
  # a blank line or a comment that ends the block is not part of the list
  while (end > start && !is_item[[end]]) {
    end <- end - 1
  }
  old <- which(is_item[seq_len(end)] & seq_len(end) > start)
  indent <- if (length(old) > 0) {
    sub("^(\\s*)- .*$", "\\1", lines[[old[[1]]]])
  } else {
    paste0(sub("^(\\s*)- .*$", "\\1", lines[[start]]), "    ")
  }
  c(
    lines[seq_len(start)],
    paste0(indent, "- ", items),
    lines[seq_along(lines)[-seq_len(end)]]
  )
}

# The books and presentations of a git branch, `character()` if it does not
# exist.
git_items <- function(ref, path_reports, path_presentations) {
  files <- git_files(ref)
  if (length(files) == 0) {
    return(character())
  }
  books <- character()
  config <- grep(
    sprintf("^%s/[^/]+/_quarto[.]yml$", path_reports), files, value = TRUE
  )
  for (file in config) {
    yaml <- tryCatch(
      yaml::yaml.load(paste(git_show(ref, file), collapse = "\n")),
      error = function(e) NULL
    )
    if (identical(yaml$project$type, "book")) {
      books <- c(books, dirname(file))
    }
  }
  slides <- grep(
    sprintf("^%s/([^/]+)/\\1[.]qmd$", path_presentations), files, value = TRUE
  )
  slides <- slides[vapply(slides, function(file) {
    any(grepl("revealjs", git_show(ref, file)))
  }, logical(1))]
  c(books, dirname(slides))
}

# Wrappers around git, so that tests can mock them.
git_fetch <- function() {
  status <- system2("git", c("fetch", "--quiet", "origin"))
  if (status != 0) {
    warning("`git fetch origin` failed: the remote branches may be old.",
            call. = FALSE)
  }
  invisible(status == 0)
}

git_files <- function(ref) {
  out <- suppressWarnings(tryCatch(
    system2("git", c("ls-tree", "-r", "--name-only", ref),
            stdout = TRUE, stderr = FALSE),
    error = function(e) character()
  ))
  if (!is.null(attr(out, "status"))) character() else out
}

git_show <- function(ref, file) {
  system2("git", c("show", paste0(ref, ":", file)),
          stdout = TRUE, stderr = FALSE)
}
