# List the available book templates

List the available book templates

## Usage

``` r
list_templates_book(packages = NULL)
```

## Arguments

- packages:

  Names of other packages whose templates are listed too.

## Value

A data frame with the template `name`, its `source` (`"user"`,
`"package"` for the templates of kquarto.r, or the name of another
package) and its `path`. A user template with the same name as a
kquarto.r template takes precedence over it. Templates of other packages
are named `"pkg::name"`.

## Templates from another package

Any package can ship templates in `inst/templates/<name>/` (each folder
containing a `_quarto.yml`). They are used with
`create_book(template = "pkg::name")`.

A package such as `kquarto.r.inrae` can also make its template the
default, either by wrapping the functions:

    create_book <- function(dirname_reports, ...,
                            template = "kquarto.r.inrae::inrae") {
      kquarto.r::create_book(dirname_reports, ..., template = template)
    }

or by setting the option `kquarto.r.template` (e.g. in its `.onLoad()`
or in a user's `.Rprofile`):
`options(kquarto.r.template = "kquarto.r.inrae::inrae")`.

## Examples

``` r
list_templates_book()
#>      name  source                                                        path
#> 1 default package /home/runner/work/_temp/Library/kquarto.r/templates/default
```
