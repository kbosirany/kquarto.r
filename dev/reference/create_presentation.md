# Create Quarto presentations

Creates one folder per presentation in `path`, containing a single
`<name>.qmd` (reveal.js slides) and the files of the template (theme,
logos, ...). Presentations are independent of books: they have their own
templates (see
[`list_templates_presentation()`](https://kbosirany.github.io/kquarto.r/dev/reference/create_template_presentation.md))
and are rendered with
[`render_presentation()`](https://kbosirany.github.io/kquarto.r/dev/reference/render_presentation.md).

## Usage

``` r
create_presentation(
  name,
  path = ".",
  title = NULL,
  subtitle = NULL,
  author = NULL,
  date = NULL,
  lang = "fr",
  template = getOption("kquarto.r.presentation.template", "default-presentation"),
  formats = NULL,
  overwrite = FALSE
)
```

## Arguments

- name:

  Presentation folder names, created in `path`. The slides are written
  in `<name>/<name>.qmd`.

- path:

  Folder where the presentation folders are created.

- title:

  Presentation title. A character vector of the same length as `name`,
  or named by `name` to set only some titles. Defaults to `name`.

- subtitle, author, date:

  Values written in the YAML header of the slides. `NULL` leaves the
  template value.

- lang:

  Language of the presentation.

- template:

  Template used to initialise the slides: the name of a presentation
  template (see
  [`list_templates_presentation()`](https://kbosirany.github.io/kquarto.r/dev/reference/create_template_presentation.md)),
  e.g. `"default-presentation"` or `"inrae-presentation"` (INRAE graphic
  charter), a template of another package (`"pkg::name"`) or the path to
  a template folder. Defaults to the option
  `kquarto.r.presentation.template`, or `"default-presentation"`.

- formats:

  Formats of the slides. `NULL` keeps those of the template
  (`"revealjs"`, HTML). Add `"beamer"` to get a PDF made with LaTeX
  (needs a LaTeX distribution, e.g. `quarto install tinytex`), rendered
  with `render_presentation(output_format = "beamer")`. Typst is not
  available: Quarto has no Typst slides.

- overwrite:

  Whether to replace the slides of an existing presentation.

## Value

The paths of the `.qmd` files, invisibly.

## Examples

``` r
tmp <- tempfile()
dir.create(tmp)
create_presentation(
  "seminaire",
  path = tmp,
  title = "Mon séminaire",
  author = "Kevin Orlando",
  template = "inrae-presentation"
)
list.files(tmp, recursive = TRUE)
#> [1] "seminaire/_brand.yml"               "seminaire/images/favicon-inrae.png"
#> [3] "seminaire/images/logo-inrae.png"    "seminaire/inrae-beamer.tex"        
#> [5] "seminaire/inrae-charte.scss"        "seminaire/inrae-slides.scss"       
#> [7] "seminaire/seminaire.qmd"           
```
