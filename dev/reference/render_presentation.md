# Render Quarto presentations

Calls
[`quarto::quarto_render()`](https://quarto-dev.github.io/quarto-r/reference/quarto_render.html)
on the slides of each presentation. The HTML file is written next to the
`.qmd`.

## Usage

``` r
render_presentation(
  dirname_presentations = NULL,
  path_presentations = "presentations",
  output_format = NULL,
  quiet = FALSE,
  output_dir = NULL,
  ...,
  workers = getOption("kquarto.r.workers", 1L),
  name = NULL,
  path = NULL
)
```

## Arguments

- dirname_presentations:

  Presentation folder names, relative to `path_presentations`. By
  default, every presentation found in `path_presentations` (see
  [`list_presentations()`](https://kbosirany.github.io/kquarto.r/dev/reference/list_presentations.md)).

- path_presentations:

  Folder containing the presentation folders.

- output_format:

  Output format passed to Quarto, e.g. `"revealjs"`, `"beamer"` (PDF,
  see the `formats` argument of
  [`create_presentation()`](https://kbosirany.github.io/kquarto.r/dev/reference/create_presentation.md))
  or `"pptx"` (PowerPoint: add a `pptx:` format with a `reference-doc`
  to the YAML header of the slides to use the masks of a PowerPoint
  template). `NULL` renders the formats of the slides.

- quiet:

  Whether to suppress Quarto output.

- output_dir:

  Folder where the rendered files are copied, in a sub-folder per
  presentation (`<output_dir>/<name>/`): the HTML slides as `index.html`
  and the PDF and PowerPoint files, if there are some, as `<name>.pdf`
  and `<name>.pptx`. `NULL` leaves the files next to the `.qmd`. Used by
  [`build_site()`](https://kbosirany.github.io/kquarto.r/dev/reference/build_site.md).

- ...:

  Other arguments passed to
  [`quarto::quarto_render()`](https://quarto-dev.github.io/quarto-r/reference/quarto_render.html).

- workers:

  Number of presentations rendered at the same time, see
  [`render_book()`](https://kbosirany.github.io/kquarto.r/dev/reference/render_book.md).

- name, path:

  Deprecated, use `dirname_presentations` and `path_presentations`.

## Value

The paths of the rendered files (`.html`, `.pdf` for
`output_format = "beamer"` or `.pptx` for `output_format = "pptx"`),
invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
create_presentation("seminaire")
render_presentation("seminaire")
} # }
```
