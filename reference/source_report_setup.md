# Source the setup of a report

Sources the file `setup.R` of a book, from the setup chunk of its
chapters. The file is found from the working directory, so the same call
works during `quarto render` (the working directory is the book folder)
and when the chunks are run by hand (the working directory is often the
project root, or any folder of it).

## Usage

``` r
source_report_setup(
  report,
  file = "setup.R",
  path_reports = "reports",
  envir = globalenv()
)
```

## Arguments

- report:

  Book folder name, e.g. `"04_run-intellirrig_fr"`.

- file:

  Name of the setup file.

- path_reports:

  Folder containing the book folders.

- envir:

  Environment where the file is evaluated. By default the global
  environment, where the chunks of a chapter are evaluated, so the
  objects it creates are available in the chunks.

## Value

The path of the sourced file, invisibly.

## Details

The file is searched in each folder from the working directory up to the
root of the file system: first `file` in the folder itself when it is
named `report`, then `path_reports/report/file`. The first one found is
sourced.

## Examples

``` r
tmp <- tempfile()
dir.create(file.path(tmp, "reports", "rapport"), recursive = TRUE)
writeLines("setup_done <- TRUE", file.path(tmp, "reports/rapport/setup.R"))
withr::with_dir(tmp, source_report_setup("rapport", envir = environment()))
setup_done
#> [1] TRUE
```
