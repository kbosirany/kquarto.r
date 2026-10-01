# Create a reusable book template

Saves a template that can then be used with
`create_book(template = name)`. A template is a folder containing at
least a `_quarto.yml`, plus any file to copy into new reports (chapters,
`references.bib`, `styles.css`, logos, ...).

## Usage

``` r
create_template_book(
  name,
  from = "default",
  overwrite = FALSE,
  dir = template_dir()
)
```

## Arguments

- name:

  Template name.

- from:

  Where the template files come from: the name of an existing template
  (by default the one shipped with the package) or the path to a folder,
  typically a report you already set up. Rendering outputs (`_book/`,
  `.quarto/`, `_freeze/`) are not copied.

- overwrite:

  Whether to replace an existing template with the same name.

- dir:

  Folder where the template is saved. Defaults to
  [`template_dir()`](https://kbosirany.github.io/kquarto.r/dev/reference/template_dir.md);
  use `"inst/templates"` from the root of a package that ships
  templates.

## Value

The path of the template folder, invisibly. Edit its files to customise
the template.

## Details

Templates are stored in
[`template_dir()`](https://kbosirany.github.io/kquarto.r/dev/reference/template_dir.md),
i.e. the user data folder of the package by default, so they are
available from every project. Set the option `kquarto.r.template_dir` to
share templates via another folder (e.g. a folder under version
control).

To ship templates in your own package (e.g. an institutional charter),
create them with `dir = "inst/templates"` in that package; they are then
available as `create_book(template = "pkg::name")`. See the "Templates
from another package" section of
[`list_templates_book()`](https://kbosirany.github.io/kquarto.r/dev/reference/list_templates_book.md).

## Examples

``` r
old <- options(kquarto.r.template_dir = tempfile())
path <- create_template_book("mon_template")
#> Template 'mon_template' created in: /tmp/Rtmp7Kbpxs/file1a197e119900/mon_template
list.files(path)
#> [1] "_quarto.yml" "index.qmd"  
list_templates_book()
#>           name  source
#> 1 mon_template    user
#> 2      default package
#>                                                          path
#> 1               /tmp/Rtmp7Kbpxs/file1a197e119900/mon_template
#> 2 /home/runner/work/_temp/Library/kquarto.r/templates/default
options(old)
```
