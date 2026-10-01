# Add the books to the navbar of a pkgdown site

Writes a menu entry for each book into the `_pkgdown.yml` file, so that
[`pkgdown::build_site()`](https://pkgdown.r-lib.org/reference/build_site.html)
links to the rendered books (see
[`build_site()`](https://kbosirany.github.io/kquarto.r/dev/reference/build_site.md)).
Books are dispatched into language-specific navbar components
(`reports_fr`, `reports_en`, ...) based on the `-fr`/`-en` suffix of
their folder name. Books without a language suffix are grouped under
`reports`.

## Usage

``` r
update_pkgdown_yml(
  dirname_reports = NULL,
  path = "reports",
  titles = NULL,
  pkgdown_file = "_pkgdown.yml",
  site_subdir = "reports",
  add_to_navbar = TRUE
)
```

## Arguments

- dirname_reports:

  Book folder names, relative to `path`. By default, every book found in
  `path` (see
  [`list_books()`](https://kbosirany.github.io/kquarto.r/dev/reference/list_books.md)).

- path:

  Folder containing the book folders.

- titles:

  Optional titles, as a character vector (or list) the same length as
  `dirname_reports`, possibly named by book folder. By default, the
  `book: title` of each `_quarto.yml`.

- pkgdown_file:

  Path to the pkgdown configuration file.

- site_subdir:

  Folder of the pkgdown site (relative to its root) where the books are
  rendered, used to build the links.

- add_to_navbar:

  Whether to add the components to `navbar: structure: left`.

## Value

The YAML list written to `pkgdown_file`, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
update_pkgdown_yml()
update_pkgdown_yml("rapport-fr", titles = "Mon rapport")
} # }
```
