# Render Quarto book reports

Calls
[`quarto::quarto_render()`](https://quarto-dev.github.io/quarto-r/reference/quarto_render.html)
on each report folder.

## Usage

``` r
render_book(
  dirname_reports = NULL,
  path = ".",
  output_dir = NULL,
  output_format = NULL,
  quiet = FALSE,
  ...
)
```

## Arguments

- dirname_reports:

  Report folder names, relative to `path`. By default, every book found
  in `path` (see
  [`list_books()`](https://kbosirany.github.io/kquarto.r/reference/list_books.md)).

- path:

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

## Value

The paths of the output folders, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
create_book("rapport")
render_book("rapport")
render_book("rapport", output_dir = "../docs/rapport")
} # }
```
