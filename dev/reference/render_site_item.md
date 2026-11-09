# Render one book or presentation in the folder of the pkgdown site

Renders `item` where
[`build_site()`](https://kbosirany.github.io/kquarto.r/dev/reference/build_site.md)
would render it: a book in `<site>/<subdir_reports>/<book>/`, a
presentation in `<site>/<subdir_presentations>/<name>/`. It is meant for
a CI job that renders each book and presentation on its own, at the same
time as the others (see
[`update_gitlab_ci()`](https://kbosirany.github.io/kquarto.r/dev/reference/update_gitlab_ci.md)).
A last job then builds the site with
`build_site(render_reports = FALSE, render_presentations = FALSE, check_rendered = TRUE)`.

## Usage

``` r
render_site_item(
  item,
  path_site = "public",
  path_reports = "reports",
  path_presentations = "presentations",
  subdir_reports = "reports",
  subdir_presentations = "presentations",
  output_format = NULL,
  clean = TRUE
)
```

## Arguments

- item:

  Folder of the book or presentation, e.g. `"reports/01_first_fr"` or
  `"presentations/seminar"`. An item that does not exist is skipped with
  a message: the matrix of the CI lists the items of several branches,
  see
  [`update_gitlab_ci()`](https://kbosirany.github.io/kquarto.r/dev/reference/update_gitlab_ci.md).

- path_site:

  Folder of the pkgdown site, see
  [`build_site()`](https://kbosirany.github.io/kquarto.r/dev/reference/build_site.md).

- path_reports, path_presentations:

  Folders containing the books and the presentations.

- subdir_reports, subdir_presentations:

  Folders of the site where each book and presentation is rendered in
  its own sub-folder.

- output_format:

  Formats rendered in addition to the HTML, see
  [`build_site()`](https://kbosirany.github.io/kquarto.r/dev/reference/build_site.md)
  (each format runs the code of the chapters again).

- clean:

  Whether to remove the previous output of the item in the site before
  rendering.

## Value

The folder of the item in the site, invisibly (`NULL` if the item does
not exist).

## Details

The HTML is always rendered, like in
[`build_site()`](https://kbosirany.github.io/kquarto.r/dev/reference/build_site.md),
and so are the formats of `output_format` that the item declares. The
site of a development version (pkgdown `development: mode`, or the
environment variable `PKGDOWN_DEV_MODE`) is `<path_site>/dev`.

## Examples

``` r
if (FALSE) { # \dontrun{
render_site_item("reports/01_first_fr")
} # }
```
