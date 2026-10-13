# Build a pkgdown site including the rendered books

Renders the books and the presentations into the pkgdown destination
folder, adds them to the navbar (see
[`update_pkgdown_yml()`](https://kbosirany.github.io/kquarto.r/dev/reference/update_pkgdown_yml.md))
and builds the site with
[`pkgdown::build_site()`](https://pkgdown.r-lib.org/reference/build_site.html).

## Usage

``` r
build_site(
  path = "reports",
  dest = "public",
  site_subdir = "reports",
  render_reports = TRUE,
  presentations_path = "presentations",
  presentations_subdir = "presentations",
  build_readme = FALSE,
  clean = TRUE,
  ...
)
```

## Arguments

- path:

  Folder containing the book folders.

- dest:

  Destination folder of the pkgdown site (the `destination` of
  `_pkgdown.yml`).

- site_subdir:

  Folder of the site, relative to `dest`, where each book is rendered in
  its own sub-folder.

- render_reports:

  Whether to render the books and the presentations, and update the
  navbar.

- presentations_path:

  Folder containing the presentation folders (see
  [`create_presentation()`](https://kbosirany.github.io/kquarto.r/dev/reference/create_presentation.md)).
  Without this folder, or without any presentation in it, there is no
  presentation on the site.

- presentations_subdir:

  Folder of the site, relative to `dest`, where each presentation is
  rendered in its own sub-folder (`index.html`, and the PDF if the
  presentation has one).

- build_readme:

  Whether to rebuild the README with
  [`devtools::build_readme()`](https://devtools.r-lib.org/reference/build_readme.html).

- clean:

  Whether to remove a book's previous output before rendering.

- ...:

  Other arguments passed to
  [`pkgdown::build_site()`](https://pkgdown.r-lib.org/reference/build_site.html).

## Value

The result of
[`pkgdown::build_site()`](https://pkgdown.r-lib.org/reference/build_site.html),
invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
build_site()
} # }
```
