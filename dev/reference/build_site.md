# Build a pkgdown site including the rendered books

Renders the books and the presentations into the pkgdown site, adds them
to the navbar (see
[`update_pkgdown_yml()`](https://kbosirany.github.io/kquarto.r/dev/reference/update_pkgdown_yml.md))
and builds the site with
[`pkgdown::build_site()`](https://pkgdown.r-lib.org/reference/build_site.html)
in `path_site`.

## Usage

``` r
build_site(
  path_reports = "reports",
  path_site = "public",
  subdir_reports = "reports",
  render_reports = TRUE,
  path_presentations = "presentations",
  subdir_presentations = "presentations",
  render_presentations = TRUE,
  build_readme = FALSE,
  clean = TRUE,
  ...,
  path = NULL,
  dest = NULL,
  site_subdir = NULL,
  presentations_path = NULL,
  presentations_subdir = NULL
)
```

## Arguments

- path_reports:

  Folder containing the book folders.

- path_site:

  Folder of the pkgdown site, e.g. `"public"` (GitLab Pages) or `"docs"`
  (GitHub Pages). It is given to pkgdown as its `destination`.

- subdir_reports:

  Folder of the site where each book is rendered in its own sub-folder.

- render_reports:

  Whether to render the books.

- path_presentations:

  Folder containing the presentation folders (see
  [`create_presentation()`](https://kbosirany.github.io/kquarto.r/dev/reference/create_presentation.md)).
  Without this folder, or without any presentation in it, there is no
  presentation on the site.

- subdir_presentations:

  Folder of the site where each presentation is rendered in its own
  sub-folder (`index.html`, and the PDF if the presentation has one).

- render_presentations:

  Whether to render the presentations. When one of `render_reports` and
  `render_presentations` is `TRUE`, the navbar is updated with every
  book and presentation found, rendered or not (the ones not rendered
  keep their previous output in the site).

- build_readme:

  Whether to rebuild the README with
  [`devtools::build_readme()`](https://devtools.r-lib.org/reference/build_readme.html).

- clean:

  Whether to remove a book's previous output before rendering.

- ...:

  Other arguments passed to
  [`pkgdown::build_site()`](https://pkgdown.r-lib.org/reference/build_site.html).

- path, site_subdir, presentations_path, presentations_subdir:

  Deprecated, use `path_reports`, `subdir_reports`, `path_presentations`
  and `subdir_presentations`.

- dest:

  Deprecated, use `path_site`. With `dest`, the books and the
  presentations are rendered in `dest` (not in its `dev` folder) and
  pkgdown writes in the `destination` of `_pkgdown.yml`, as before.

## Value

The result of
[`pkgdown::build_site()`](https://pkgdown.r-lib.org/reference/build_site.html),
invisibly.

## Details

The site of a development version (pkgdown `development: mode`) is
written by pkgdown in `<path_site>/dev`: the books and the presentations
go there too, so that the links of its navbar work.

## Examples

``` r
if (FALSE) { # \dontrun{
build_site()
} # }
```
