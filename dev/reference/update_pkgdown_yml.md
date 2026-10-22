# Add the books to the navbar of a pkgdown site

Writes a menu entry for each book into the `_pkgdown.yml` file, so that
[`pkgdown::build_site()`](https://pkgdown.r-lib.org/reference/build_site.html)
links to the rendered books (see
[`build_site()`](https://kbosirany.github.io/kquarto.r/dev/reference/build_site.md)).
The books form one navbar menu, `reports`. Each book has a category:
`package` (the reference material about the package functions) when its
folder name starts with a number (`01_...`), `others` otherwise (project
report, meeting...); a `category: package` or `category: others` key in
its `_quarto.yml` overrides it. With both categories, the menu has a
header by category (`Package`, `Others`), suffixed by the language
(`[en]`, `[fr]`, the `_en`/`_fr` suffix of the folder name) when there
are several languages. With a single category, the menu has a header by
language (`English`, `Français`) when there are several languages, none
otherwise. The `package` items are sorted by folder name, the `others`
items by date (folder name starting with `YYYYMMDD`), most recent first,
then by folder name. The components `reports_en` and `reports_fr`
written by former versions are removed.

## Usage

``` r
update_pkgdown_yml(
  dirname_reports = NULL,
  path = "reports",
  titles = NULL,
  pkgdown_file = "_pkgdown.yml",
  site_subdir = "reports",
  add_to_navbar = TRUE,
  presentations = NULL,
  presentations_path = "presentations",
  presentations_site_subdir = "presentations"
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

- presentations:

  Presentation folder names, relative to `presentations_path`. By
  default, every presentation found in `presentations_path` (see
  [`list_presentations()`](https://kbosirany.github.io/kquarto.r/dev/reference/list_presentations.md)).
  They form the navbar menu `presentations`, titled after the `title` of
  their slides, with headers by category and language as the books (the
  `category` key overriding the category is in the YAML header of the
  slides); without any presentation, the menu is removed.

- presentations_path:

  Folder containing the presentation folders.

- presentations_site_subdir:

  Folder of the pkgdown site (relative to its root) where the
  presentations are rendered, used to build the links.

## Value

The YAML list written to `pkgdown_file`, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
update_pkgdown_yml()
update_pkgdown_yml("rapport_fr", titles = "Mon rapport")
} # }
```
