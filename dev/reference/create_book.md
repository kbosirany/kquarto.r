# Create one or several Quarto book reports

Creates a folder for each report in `dirname_reports`, copies the files
of `template` into it and writes a `_quarto.yml` (project of type
`book`) filled with the given title, author, language, ...

## Usage

``` r
create_book(
  dirname_reports,
  path = ".",
  title = NULL,
  author = NULL,
  lang = "fr",
  date = NULL,
  template = getOption("kquarto.r.template", "default"),
  output_dir = "_book",
  chapters = NULL,
  chapter_prefix = NULL,
  ...,
  overwrite = FALSE
)
```

## Arguments

- dirname_reports:

  Character vector of report folder names, relative to `path`.

- path:

  Folder in which the report folders are created. Defaults to the
  working directory.

- title:

  Book title(s). By default the name of each report folder. Otherwise
  either a single title (only when one report is created), an unnamed
  vector of the same length as `dirname_reports`, or a vector named by
  the report folders.

- author:

  Character vector of authors, written in `book: author`.

- lang:

  Document language (`lang` field), e.g. `"fr"` or `"en"`.

- date:

  Book date (`book: date`), e.g. `"today"` or `"last-modified"`. `NULL`
  to leave the template value.

- template:

  Template used to initialise the reports: the name of a template (see
  [`list_templates_book()`](https://kbosirany.github.io/kquarto.r/dev/reference/list_templates_book.md)),
  a template shipped by another package as `"pkg::name"`, or the path to
  a folder that contains a `_quarto.yml`. Defaults to the option
  `kquarto.r.template`, or `"default"`.

- output_dir:

  Output folder of the rendered book, relative to the report folder
  (`project: output-dir`).

- chapters:

  Optional character vector of chapter names. Each one creates a
  numbered chapter file after `index.qmd` with
  [`create_book_chapter()`](https://kbosirany.github.io/kquarto.r/dev/reference/create_book_chapter.md),
  e.g. `chapitre-01-introduction.qmd`. A chapter whose file already
  exists is not created again.

- chapter_prefix:

  Prefix of the chapter files. By default `"chapitre"` when `lang` is
  French, `"chapter"` otherwise.

- ...:

  Additional fields merged (recursively) into `_quarto.yml`, e.g.
  `format = list(html = list(theme = "flatly"))` or
  `book = list(chapters = c("index.qmd", "methodes.qmd"))`.

- overwrite:

  If `FALSE` (the default), an error is raised when a report folder
  already contains a `_quarto.yml`. If `TRUE`, the `_quarto.yml` and the
  template files are overwritten; chapters already listed in the old
  `_quarto.yml` whose file still exists are kept in `book: chapters`,
  after those of the template.

## Value

The paths of the report folders, invisibly.

## Details

When `path` is the root of an R package (it contains a `DESCRIPTION`
file), the report folders are also added to `.Rbuildignore`.

## Examples

``` r
tmp <- tempfile()
dir.create(tmp)
create_book(
  c("rapport_technique", "note_synthese"),
  path = tmp,
  title = c(note_synthese = "Note de synthèse"),
  author = "Kevin Orlando",
  chapters = c("Introduction", "M\u00e9thodes", "R\u00e9sultats")
)
#> Book(s) created: rapport_technique, note_synthese
list.files(tmp, recursive = TRUE)
#>  [1] "note_synthese/_quarto.yml"                     
#>  [2] "note_synthese/chapitre-01-introduction.qmd"    
#>  [3] "note_synthese/chapitre-02-methodes.qmd"        
#>  [4] "note_synthese/chapitre-03-resultats.qmd"       
#>  [5] "note_synthese/index.qmd"                       
#>  [6] "rapport_technique/_quarto.yml"                 
#>  [7] "rapport_technique/chapitre-01-introduction.qmd"
#>  [8] "rapport_technique/chapitre-02-methodes.qmd"    
#>  [9] "rapport_technique/chapitre-03-resultats.qmd"   
#> [10] "rapport_technique/index.qmd"                   
```
