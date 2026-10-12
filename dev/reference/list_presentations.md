# List the presentations of a folder

A presentation is a folder `<name>/` containing a `<name>.qmd` whose
format is `revealjs`.

## Usage

``` r
list_presentations(path = ".")
```

## Arguments

- path:

  Folder containing the presentation folders.

## Value

The names of the presentation folders.

## Examples

``` r
tmp <- tempfile()
dir.create(tmp)
create_presentation("seminaire", path = tmp)
list_presentations(tmp)
#> [1] "seminaire"
```
