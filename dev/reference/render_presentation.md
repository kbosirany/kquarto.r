# Render Quarto presentations

Calls
[`quarto::quarto_render()`](https://quarto-dev.github.io/quarto-r/reference/quarto_render.html)
on the slides of each presentation. The HTML file is written next to the
`.qmd`.

## Usage

``` r
render_presentation(
  name = NULL,
  path = ".",
  output_format = NULL,
  quiet = FALSE,
  ...
)
```

## Arguments

- name:

  Presentation folder names, relative to `path`. By default, every
  presentation found in `path` (see
  [`list_presentations()`](https://kbosirany.github.io/kquarto.r/dev/reference/list_presentations.md)).

- path:

  Folder containing the presentation folders.

- output_format:

  Output format passed to Quarto, e.g. `"revealjs"` or `"beamer"` (PDF,
  see the `formats` argument of
  [`create_presentation()`](https://kbosirany.github.io/kquarto.r/dev/reference/create_presentation.md)).
  `NULL` renders the formats of the slides.

- quiet:

  Whether to suppress Quarto output.

- ...:

  Other arguments passed to
  [`quarto::quarto_render()`](https://quarto-dev.github.io/quarto-r/reference/quarto_render.html).

## Value

The paths of the rendered files (`.html`, or `.pdf` for
`output_format = "beamer"`), invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
create_presentation("seminaire")
render_presentation("seminaire")
} # }
```
