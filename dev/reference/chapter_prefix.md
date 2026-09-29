# Default chapter file prefix for a language

Default chapter file prefix for a language

## Usage

``` r
chapter_prefix(lang)
```

## Arguments

- lang:

  A language code such as `"fr"`, `"fr-FR"` or `"en"`.

## Value

`"chapitre"` for French, `"chapter"` otherwise.

## Examples

``` r
chapter_prefix("fr-FR")
#> [1] "chapitre"
chapter_prefix("en")
#> [1] "chapter"
```
