# Add a chapter to a Quarto book

Creates a numbered chapter file (e.g. `chapitre-03-methodes.qmd`) in a
book folder and appends it to `book: chapters` in `_quarto.yml`. The
number is the highest existing number for this prefix, plus one, so
`index.qmd` is never touched and chapters start at `01`.

## Usage

``` r
create_book_chapter(book, name, path = ".", title = name, prefix = NULL)
```

## Arguments

- book:

  Book folder name, relative to `path`.

- name:

  Chapter name, without prefix nor number. It is converted to a file
  name (lower case, no accents, words separated by `-`).

- path:

  Folder containing the book folder.

- title:

  Chapter title written as first heading of the file. By default `name`.

- prefix:

  File name prefix. By default derived from the `lang` of the book's
  `_quarto.yml`: `"chapitre"` for French, `"chapter"` otherwise (see
  [`chapter_prefix()`](https://kbosirany.github.io/kquarto.r/dev/reference/chapter_prefix.md)).

## Value

The path of the chapter file, invisibly.

## Examples

``` r
tmp <- tempfile()
dir.create(tmp)
create_book("rapport", path = tmp, lang = "fr")
#> Book(s) created: rapport
create_book_chapter("rapport", "Introduction", path = tmp)
#> Chapter created: rapport/chapitre-01-introduction.qmd
create_book_chapter("rapport", "Matériel et méthodes", path = tmp)
#> Chapter created: rapport/chapitre-02-materiel-et-methodes.qmd
list.files(file.path(tmp, "rapport"))
#> [1] "_quarto.yml"                         
#> [2] "chapitre-01-introduction.qmd"        
#> [3] "chapitre-02-materiel-et-methodes.qmd"
#> [4] "index.qmd"                           
```
