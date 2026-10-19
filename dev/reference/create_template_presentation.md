# Manage presentation templates

Presentation templates live in the same folders as book templates (see
[`template_dir()`](https://kbosirany.github.io/kquarto.r/dev/reference/template_dir.md)),
but a `template.yml` declares their `type`, so
[`list_templates_book()`](https://kbosirany.github.io/kquarto.r/dev/reference/list_templates_book.md)
and `list_templates_presentation()` never mix. A presentation template
is a folder with a `template.yml` (`type: presentation`), a `slides.qmd`
(reveal.js slides with a YAML header) and any file it needs (theme,
logos, ...). A template can reuse the files of a shared charter with
`shared: <name>` in its `template.yml` (folder `shared/<name>/` next to
`templates/` in the package): they are copied into each presentation,
and into user templates created from it.

## Usage

``` r
create_template_presentation(
  name,
  from = "default-presentation",
  overwrite = FALSE,
  dir = template_dir()
)

list_templates_presentation(packages = NULL)

remove_template_presentation(name)
```

## Arguments

- name:

  Template name.

- from:

  Where the template files come from: the name of an existing
  presentation template (by default the one shipped with the package) or
  the path to a folder, typically a presentation you already set up.

- overwrite:

  Whether to replace an existing template with the same name.

- dir:

  Folder where the template is saved. Defaults to
  [`template_dir()`](https://kbosirany.github.io/kquarto.r/dev/reference/template_dir.md);
  use `"inst/templates"` from the root of a package that ships
  templates.

- packages:

  Names of other packages whose templates are listed too.

## Value

`create_template_presentation()` returns the path of the template
folder, invisibly. `list_templates_presentation()` returns a data frame
with the template `name`, its `source` and its `path`.
`remove_template_presentation()` returns `TRUE` invisibly.

## Examples

``` r
old <- options(kquarto.r.template_dir = tempfile())
list_templates_presentation()
#>                   name  source
#> 1 default-presentation package
#> 2   inrae-presentation package
#>                                                                       path
#> 1 /home/runner/work/_temp/Library/kquarto.r/templates/default-presentation
#> 2   /home/runner/work/_temp/Library/kquarto.r/templates/inrae-presentation
create_template_presentation("ma_charte", from = "inrae-presentation")
#> Template 'ma_charte' created in: /tmp/RtmpGbtK7v/file199455ab2a32/ma_charte
options(old)
```
