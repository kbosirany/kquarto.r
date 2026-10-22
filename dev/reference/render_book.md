# Render Quarto book reports

Calls
[`quarto::quarto_render()`](https://quarto-dev.github.io/quarto-r/reference/quarto_render.html)
on each report folder.

## Usage

``` r
render_book(
  dirname_reports = NULL,
  path_reports = "reports",
  output_dir = NULL,
  output_format = NULL,
  quiet = FALSE,
  ...,
  workers = getOption("kquarto.r.workers", 1L),
  path = NULL
)
```

## Arguments

- dirname_reports:

  Report folder names, relative to `path_reports`. By default, every
  book found in `path_reports` (see
  [`list_books()`](https://kbosirany.github.io/kquarto.r/dev/reference/list_books.md)).

- path_reports:

  Folder containing the report folders.

- output_dir:

  Where the rendered book is written. `NULL` (the default) keeps the
  `output-dir` of the `_quarto.yml`, i.e. `_book/` inside the report
  folder. Otherwise a path relative to each report folder, e.g.
  `"../../docs/rapport"`.

- output_format:

  Output format(s) passed to Quarto, e.g. `"html"`, `"pdf"` or `"all"`.
  `NULL` renders the formats of the `_quarto.yml`.

- quiet:

  Whether to suppress Quarto output.

- ...:

  Other arguments passed to
  [`quarto::quarto_render()`](https://quarto-dev.github.io/quarto-r/reference/quarto_render.html).

- workers:

  Number of books rendered at the same time. With `1` (the default, or
  the option `kquarto.r.workers`), the books are rendered one after the
  other in the current session. With more, each book is rendered in a
  background R session (on every OS), its Quarto output going to a log
  file shown when it fails; every book is rendered even if one fails,
  and the error lists the failed ones. Each render needs its own memory
  (an R session, and Chrome for the PDF of interactive content), e.g.
  `workers = parallel::detectCores() - 1` on a machine with enough
  memory.

- path:

  Deprecated, use `path_reports`.

## Value

The paths of the output folders, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
create_book("rapport")
render_book("rapport")
render_book("rapport", output_dir = "../../docs/rapport")
render_book(workers = 3)
} # }
```
