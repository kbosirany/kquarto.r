# List the Quarto books of a folder

List the Quarto books of a folder

## Usage

``` r
list_books(path = ".", recursive = FALSE)
```

## Arguments

- path:

  Folder to search in.

- recursive:

  Whether to search in subfolders.

## Value

The names (relative to `path`) of the folders containing a `_quarto.yml`
of type `book`.

## Examples

``` r
tmp <- tempfile()
dir.create(tmp)
create_book(c("rapport_a", "rapport_b"), path = tmp)
#> Book(s) created: rapport_a, rapport_b
list_books(tmp)
#> [1] "rapport_a" "rapport_b"
```
