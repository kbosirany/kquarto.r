#' Render Quarto book reports
#'
#' Calls [quarto::quarto_render()] on each report folder.
#'
#' @param dirname_reports Report folder names, relative to `path_reports`.
#'   By default, every book found in `path_reports` (see [list_books()]).
#' @param path_reports Folder containing the report folders.
#' @param output_dir Where the rendered book is written. `NULL` (the default)
#'   keeps the `output-dir` of the `_quarto.yml`, i.e. `_book/` inside the
#'   report folder. Otherwise a path relative to each report folder, e.g.
#'   `"../../docs/rapport"`.
#' @param output_format Output format(s) passed to Quarto, e.g. `"html"`,
#'   `"pdf"` or `"all"`. `NULL` renders the formats of the `_quarto.yml`.
#' @param quiet Whether to suppress Quarto output.
#' @param ... Other arguments passed to [quarto::quarto_render()].
#' @param workers Number of books rendered at the same time. With `1` (the
#'   default, or the option `kquarto.r.workers`), the books are rendered one
#'   after the other in the current session. With more, each book is
#'   rendered in a background R session (on every OS), its Quarto output
#'   going to a log file shown when it fails; every book is rendered even
#'   if one fails, and the error lists the failed ones. Each render needs
#'   its own memory (an R session, and Chrome for the PDF of interactive
#'   content), e.g. `workers = parallel::detectCores() - 1` on a machine
#'   with enough memory.
#' @param path Deprecated, use `path_reports`.
#'
#' @return The paths of the output folders, invisibly.
#' @export
#'
#' @examples
#' \dontrun{
#' create_book("rapport")
#' render_book("rapport")
#' render_book("rapport", output_dir = "../../docs/rapport")
#' render_book(workers = 3)
#' }
render_book <- function(dirname_reports = NULL,
                        path_reports = "reports",
                        output_dir = NULL,
                        output_format = NULL,
                        quiet = FALSE,
                        ...,
                        workers = getOption("kquarto.r.workers", 1L),
                        path = NULL) {
  path_reports <- renamed_arg(path_reports, path, "path_reports", "path")
  renders <- book_renders(
    dirname_reports, path_reports, output_dir, output_format, quiet, ...
  )
  run_renders(renders, workers)
  invisible(vapply(renders, function(x) x$output, character(1)))
}

# The renders of books: for each one, a list of its `label` (folder name),
# the `args` of quarto::quarto_render() and its `output` folder. See
# run_renders().
book_renders <- function(dirname_reports, path_reports, output_dir = NULL,
                         output_format = NULL, quiet = FALSE, ...) {
  if (is.null(dirname_reports)) {
    dirname_reports <- list_books(path_reports)
    if (length(dirname_reports) == 0) {
      stop("No Quarto book found in: ", path_reports, call. = FALSE)
    }
  }
  check_dirnames(dirname_reports)
  report_dirs <- file.path(path_reports, dirname_reports)
  missing <- !file.exists(file.path(report_dirs, "_quarto.yml"))
  if (any(missing)) {
    stop(
      "No `_quarto.yml` in: ", paste(dirname_reports[missing], collapse = ", "),
      ". Create the book with `create_book()` first.",
      call. = FALSE
    )
  }

  dots <- list(...)
  quarto_args <- dots$quarto_args
  dots$quarto_args <- NULL
  if (!is.null(output_dir)) {
    quarto_args <- c(quarto_args, "--output-dir", output_dir)
  }

  lapply(seq_along(report_dirs), function(i) {
    report_dir <- normalizePath(report_dirs[[i]])
    args <- c(
      list(
        input = report_dir,
        output_format = output_format,
        quiet = quiet,
        quarto_args = quarto_args
      ),
      dots
    )
    out_dir <- output_dir %||% book_output_dir(report_dir)
    list(
      label = dirname_reports[[i]],
      args = args,
      output = file.path(report_dir, out_dir)
    )
  })
}

book_output_dir <- function(report_dir) {
  config <- yaml::read_yaml(file.path(report_dir, "_quarto.yml"))
  config$project$`output-dir` %||% "_book"
}

# Runs renders (lists of a `label` and the `args` of quarto::quarto_render(),
# see book_renders()). With one worker, one after the other in the current
# session, stopping at the first error. With more, `workers` at a time, each
# in a background R session (callr): a render is mostly a Quarto process, so
# this works on every OS. The output of each render goes to a log file, not
# quiet whatever `quiet`, and is shown when it fails; the error comes once
# every render is done. `fun` is
# called in the background session with the `args`: it must be
# self-contained (callr does not keep its environment).
run_renders <- function(renders, workers = 1L, fun = render_in_session) {
  check_workers(workers)
  if (length(renders) == 0) {
    return(invisible(renders))
  }
  if (is.null(quarto_bin())) {
    stop(
      "The Quarto CLI was not found. Install it from https://quarto.org.",
      call. = FALSE
    )
  }
  if (workers == 1 || length(renders) == 1) {
    for (render in renders) do.call(quarto_render, render$args)
    return(invisible(renders))
  }

  labels <- vapply(renders, function(x) x$label, character(1))
  logs <- vapply(labels, function(label) {
    tempfile(paste0(gsub("[^A-Za-z0-9_-]", "_", label), "-"), fileext = ".log")
  }, character(1))
  errors <- vector("list", length(renders))
  queue <- seq_along(renders)
  running <- list()
  started <- list()
  # interrupted: the renders still running are stopped
  on.exit(for (p in running) p$kill(), add = TRUE)

  while (length(queue) > 0 || length(running) > 0) {
    while (length(running) < workers && length(queue) > 0) {
      i <- queue[[1]]
      queue <- queue[-1]
      message("Rendering: ", labels[[i]])
      started[[i]] <- Sys.time()
      args <- renders[[i]]$args
      args$quiet <- FALSE
      running[[as.character(i)]] <- callr::r_bg(
        fun,
        args = list(args),
        stdout = logs[[i]],
        stderr = "2>&1"
      )
    }
    done <- !vapply(running, function(p) p$is_alive(), logical(1))
    for (key in names(running)[done]) {
      i <- as.integer(key)
      errors[i] <- list(tryCatch(
        {
          running[[key]]$get_result()
          NULL
        },
        error = function(e) e
      ))
      elapsed <- format(round(Sys.time() - started[[i]]))
      message(
        if (is.null(errors[[i]])) "Rendered: " else "Failed: ",
        labels[[i]], " (", elapsed, ")"
      )
    }
    running <- running[!done]
    if (!any(done)) Sys.sleep(0.2)
  }

  failed <- which(!vapply(errors, is.null, logical(1)))
  for (i in failed) {
    log <- if (file.exists(logs[[i]])) readLines(logs[[i]], warn = FALSE)
    # the log ends with the error of the session
    if (length(log) == 0) log <- conditionMessage(errors[[i]])
    message(
      "\n--- ", labels[[i]], " (full log: ", logs[[i]], ") ---\n",
      paste(utils::tail(log, 40), collapse = "\n")
    )
  }
  if (length(failed) > 0) {
    stop(
      "Rendering failed for: ", paste(labels[failed], collapse = ", "),
      ". See the logs above.",
      call. = FALSE
    )
  }
  invisible(renders)
}

# Called in a background R session by run_renders(). The LD_LIBRARY_PATH set
# by R makes Quarto crash, as in quarto_render().
render_in_session <- function(args) {
  Sys.unsetenv("LD_LIBRARY_PATH")
  do.call(quarto::quarto_render, args)
  invisible()
}

check_workers <- function(workers) {
  if (!is.numeric(workers) || length(workers) != 1 || is.na(workers) ||
      workers < 1 || workers != round(workers)) {
    stop("`workers` must be a whole number, 1 or more.", call. = FALSE)
  }
  invisible(TRUE)
}

# Wrappers around quarto, so that tests can mock them. The LD_LIBRARY_PATH
# set by R makes Quarto crash (AssertionError); Quarto's R child process sets
# its own anyway.
quarto_render <- function(...) {
  withr::with_envvar(
    c(LD_LIBRARY_PATH = NA),
    quarto::quarto_render(...)
  )
}

quarto_bin <- function() {
  quarto::quarto_path()
}

`%||%` <- function(x, y) if (is.null(x)) y else x
