# Folder where user templates are stored

Returns the option `kquarto.r.template_dir` if set, otherwise
`tools::R_user_dir("kquarto.r", "data")/templates`.

## Usage

``` r
template_dir()
```

## Value

A path.

## Examples

``` r
template_dir()
#> [1] "/home/runner/.local/share/R/kquarto.r/templates"
```
