#' Add a chapter to a Quarto book
#'
#' Creates a numbered chapter file (e.g. `chapitre-03-methodes.qmd`) in a
#' book folder and appends it to `book: chapters` in `_quarto.yml`. The
#' number is the highest existing number for this prefix, plus one, so
#' `index.qmd` is never touched and chapters start at `01`.
#'
#' @param book Book folder name, relative to `path`.
#' @param name Chapter name, without prefix nor number. It is converted to a
#'   file name (lower case, no accents, words separated by `-`).
#' @param path Folder containing the book folder.
#' @param title Chapter title written as first heading of the file. By
#'   default `name`.
#' @param prefix File name prefix. By default derived from the `lang` of the
#'   book's `_quarto.yml`: `"chapitre"` for French, `"chapter"` otherwise
#'   (see [chapter_prefix()]).
#'
#' @return The path of the chapter file, invisibly.
#' @export
#'
#' @examples
#' tmp <- tempfile()
#' dir.create(tmp)
#' create_book("rapport", path = tmp, lang = "fr")
#' create_book_chapter("rapport", "Introduction", path = tmp)
#' create_book_chapter("rapport", "Matériel et méthodes", path = tmp)
#' list.files(file.path(tmp, "rapport"))
create_book_chapter <- function(book, name, path = ".", title = name, prefix = NULL) {
  if (!is.character(name) || length(name) != 1 || is.na(name) || !nzchar(name)) {
    stop("`name` must be a single non-empty string.", call. = FALSE)
  }
  book_dir <- file.path(path, book)
  yml <- file.path(book_dir, "_quarto.yml")
  if (!file.exists(yml)) {
    stop("No `_quarto.yml` in: ", book_dir, ". Create the book with `create_book()` first.",
         call. = FALSE)
  }
  config <- yaml::read_yaml(yml)
  prefix <- prefix %||% chapter_prefix(config$lang)
  slug <- slugify(name)
  if (!nzchar(slug)) {
    stop("`name` does not contain any letter or digit: ", name, call. = FALSE)
  }

  number <- next_chapter_number(book_dir, prefix)
  file <- sprintf("%s-%02d-%s.qmd", prefix, number, slug)
  writeLines(c(paste("#", title), ""), file.path(book_dir, file))

  config$book$chapters <- c(as.list(config$book$chapters), list(file))
  write_quarto_yml(config, yml)
  message("Chapter created: ", file.path(book, file))
  invisible(normalizePath(file.path(book_dir, file)))
}

#' Default chapter file prefix for a language
#'
#' @param lang A language code such as `"fr"`, `"fr-FR"` or `"en"`.
#'
#' @return `"chapitre"` for French, `"chapter"` otherwise.
#' @export
#'
#' @examples
#' chapter_prefix("fr-FR")
#' chapter_prefix("en")
chapter_prefix <- function(lang) {
  if (!is.null(lang) && grepl("^fr([-_]|$)", tolower(lang))) "chapitre" else "chapter"
}

next_chapter_number <- function(book_dir, prefix) {
  pattern <- paste0("^", escape_regex(prefix), "-([0-9]+)-.*\\.qmd$")
  files <- list.files(book_dir, pattern = pattern)
  if (length(files) == 0) {
    return(1L)
  }
  max(as.integer(sub(pattern, "\\1", files))) + 1L
}

slugify <- function(x) {
  x <- enc2utf8(x)
  # Common accented letters are mapped explicitly: iconv's transliteration
  # differs between platforms (e.g. "\u00e9" becomes "'e" on macOS).
  x <- chartr(
    "\u00e0\u00e2\u00e4\u00e1\u00e3\u00e9\u00e8\u00ea\u00eb\u00ed\u00ec\u00ee\u00ef\u00f3\u00f2\u00f4\u00f6\u00f5\u00fa\u00f9\u00fb\u00fc\u00fd\u00ff\u00e7\u00f1\u00c0\u00c2\u00c4\u00c1\u00c3\u00c9\u00c8\u00ca\u00cb\u00cd\u00cc\u00ce\u00cf\u00d3\u00d2\u00d4\u00d6\u00d5\u00da\u00d9\u00db\u00dc\u00dd\u0178\u00c7\u00d1",
    "aaaaaeeeeiiiiooooouuuuyycnAAAAAEEEEIIIIOOOOOUUUUYYCN",
    x
  )
  x <- gsub("\u0153", "oe", gsub("\u00e6", "ae", x))
  x <- gsub("\u0152", "OE", gsub("\u00c6", "AE", x))
  x <- iconv(x, from = "UTF-8", to = "ASCII//TRANSLIT", sub = "")
  x <- gsub("['`^~\"]", "", x)
  x <- tolower(x)
  x <- gsub("[^a-z0-9]+", "-", x)
  gsub("^-+|-+$", "", x)
}
