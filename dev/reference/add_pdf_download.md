# Add a PDF download to existing Quarto books

Adds a PDF format to the `_quarto.yml` of existing books and a "Download
PDF" icon to the sidebar of their HTML version
(`book: downloads: [pdf]`). The other fields of the `_quarto.yml` are
kept. Render then all the formats with
`render_book(output_format = "all")`: the icon links to the PDF of the
output folder.

## Usage

``` r
add_pdf_download(
  dirname_reports,
  path = ".",
  format = c("typst", "pdf"),
  template = NULL
)
```

## Arguments

- dirname_reports:

  Character vector of book folder names, relative to `path`.

- path:

  Folder in which the report folders are created. Defaults to the
  working directory.

- format:

  PDF engine: `"typst"` (the default, bundled with Quarto) or `"pdf"`
  (LaTeX).

- template:

  Optional template whose `typst.yml` / `pdf.yml` styles the PDF (e.g.
  `"inrae"`). Its files missing from the book (e.g. `inrae.typ`,
  `_brand.yml`) are copied; existing files are not overwritten. `NULL`
  uses a plain style (table of contents, numbered sections, A4).

## Value

The paths of the book folders, invisibly.

## Details

Interactive content (leaflet, plotly, DT, ...) has no PDF rendering:
show it only in the HTML with
`::: {.content-visible when-format="html"}` and give a static version
for the PDF.

## Examples

``` r
tmp <- tempfile()
dir.create(tmp)
create_book("rapport", path = tmp, template = "inrae", author = "Kevin")
#> Book(s) created: rapport
add_pdf_download("rapport", path = tmp, template = "inrae")
#> PDF download added to: rapport
cat(readLines(file.path(tmp, "rapport", "_quarto.yml")), sep = "\n")
#> project:
#>   type: book
#>   output-dir: _book
#> book:
#>   title: rapport
#>   subtitle: Sous-titre du rapport
#>   date: today
#>   date-format: long
#>   chapters:
#>   - index.qmd
#>   favicon: images/favicon-inrae.png
#>   sidebar:
#>     logo: images/logo-inrae.png
#>     style: docked
#>   page-footer:
#>     left: INRAE
#>     right: Rapport rédigé avec [Quarto](https://quarto.org)
#>   author:
#>   - Kevin
#>   downloads:
#>   - pdf
#> bibliography: references.bib
#> link-citations: true
#> lang: fr
#> format:
#>   html:
#>     theme:
#>     - cosmo
#>     - inrae-charte.scss
#>     - inrae.scss
#>     toc: true
#>     number-sections: true
#>     reference-location: margin
#>     citation-location: document
#>   typst:
#>     toc: true
#>     number-sections: true
#>     papersize: a4
#>     include-in-header: inrae.typ
```
