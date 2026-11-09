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
  output_format = NULL,
  check_rendered = FALSE,
  workers = getOption("kquarto.r.workers", 1L),
  ...
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

  Whether to render the presentations. The navbar is updated with every
  book and presentation found, rendered or not (the ones not rendered
  keep their previous output in the site, e.g. rendered by other CI
  jobs).

- build_readme:

  Whether to rebuild the README with
  [`devtools::build_readme()`](https://devtools.r-lib.org/reference/build_readme.html).

- clean:

  Whether to remove a book's previous output before rendering.

- output_format:

  Formats rendered in addition to the HTML, which is always rendered
  (`"html"` for the books, `"revealjs"` for the presentations), e.g.
  `"typst"`, `"pdf"` for the books or `"beamer"`, `"pptx"` for the
  presentations. Only given to
  [`render_book()`](https://kbosirany.github.io/kquarto.r/dev/reference/render_book.md)
  and
  [`render_presentation()`](https://kbosirany.github.io/kquarto.r/dev/reference/render_presentation.md),
  not to pkgdown. A book or presentation that does not declare a format
  is not rendered in it. `"all"` renders all the formats of each one.
  The additional files of a book are added to its folder in the site.
  Each format runs the code of the chapters again (`execute: freeze`
  does not share the results between formats): cache the slow
  computations in the chapters, e.g. with
  [`saveRDS()`](https://rdrr.io/r/base/readRDS.html).

- check_rendered:

  Whether to stop if a book (with `render_reports = FALSE`) or a
  presentation (with `render_presentations = FALSE`) is not in the site
  yet, as rendered by
  [`render_site_item()`](https://kbosirany.github.io/kquarto.r/dev/reference/render_site_item.md)
  in other CI jobs.

- workers:

  Number of books and presentations rendered at the same time, see
  [`render_book()`](https://kbosirany.github.io/kquarto.r/dev/reference/render_book.md).

- ...:

  Other arguments passed to
  [`pkgdown::build_site()`](https://pkgdown.r-lib.org/reference/build_site.html).

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
