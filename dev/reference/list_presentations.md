# List the presentations of a folder

A presentation is a folder `<name>/` containing a `<name>.qmd` whose
format is `revealjs`.

## Usage

``` r
list_presentations(path_presentations = "presentations", path = NULL)
```

## Arguments

- path_presentations:

  Folder containing the presentation folders.

- path:

  Deprecated, use `path_presentations`.

## Value

The names of the presentation folders.

## Examples

``` r
tmp <- tempfile()
dir.create(tmp)
create_presentation("seminaire", path_presentations = tmp)
list_presentations(tmp)
#> [1] "seminaire"
```
