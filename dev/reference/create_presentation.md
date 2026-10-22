# Create Quarto presentations

Creates one folder per presentation in `path_presentations`, containing
a single `<name>.qmd` (reveal.js slides) and the files of the template
(theme, logos, ...). Presentations are independent of books: they have
their own templates (see
[`list_templates_presentation()`](https://kbosirany.github.io/kquarto.r/dev/reference/create_template_presentation.md))
and are rendered with
[`render_presentation()`](https://kbosirany.github.io/kquarto.r/dev/reference/render_presentation.md).

## Usage

``` r
create_presentation(
  dirname_presentations,
  path_presentations = "presentations",
  title = NULL,
  subtitle = NULL,
  author = NULL,
  date = NULL,
  lang = "fr",
  template = getOption("kquarto.r.presentation.template", "default-presentation"),
  formats = NULL,
  overwrite = FALSE,
  name = NULL,
  path = NULL
)
```

## Arguments

- dirname_presentations:

  Presentation folder names, created in `path_presentations`. The slides
  are written in `<name>/<name>.qmd`.

- path_presentations:

  Folder where the presentation folders are created.

- title:

  Presentation title. A character vector of the same length as
  `dirname_presentations`, or named by `dirname_presentations` to set
  only some titles. Defaults to `dirname_presentations`.

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

- name, path:

  Deprecated, use `dirname_presentations` and `path_presentations`.

## Value

The paths of the `.qmd` files, invisibly.

## Examples

``` r
tmp <- tempfile()
dir.create(tmp)
create_presentation(
  "seminaire",
  path_presentations = tmp,
  title = "Mon séminaire",
  author = "Kevin Orlando",
  template = "inrae-presentation"
)
list.files(tmp, recursive = TRUE)
#>  [1] "seminaire/_brand.yml"                 
#>  [2] "seminaire/images/favicon-inrae.png"   
#>  [3] "seminaire/images/inrae-pied.png"      
#>  [4] "seminaire/images/inrae-titre-vert.png"
#>  [5] "seminaire/images/inrae-titre.png"     
#>  [6] "seminaire/images/logo-inrae.png"      
#>  [7] "seminaire/inrae-beamer.tex"           
#>  [8] "seminaire/inrae-charte.scss"          
#>  [9] "seminaire/inrae-slides.scss"          
#> [10] "seminaire/seminaire.qmd"              
```
