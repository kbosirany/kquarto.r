# Update the list of books and presentations in the GitLab CI

Rewrites the list of the matrix of the job that renders each book and
presentation in its own job, in `.gitlab-ci.yml`:

## Usage

``` r
update_gitlab_ci(
  path_ci = ".gitlab-ci.yml",
  path_reports = "reports",
  path_presentations = "presentations",
  refs = c("origin/main", "origin/dev"),
  variable = "ITEM",
  fetch = FALSE
)
```

## Arguments

- path_ci:

  Path to the GitLab CI file.

- path_reports:

  Folder containing the book folders.

- path_presentations:

  Folder containing the presentation folders.

- refs:

  Git branches whose books and presentations are added to those of the
  working directory. A branch that does not exist is ignored (run
  `git fetch` to update the remote ones).

- variable:

  Name of the variable of the matrix that has the items.

- fetch:

  Whether to run `git fetch origin` first, so that the remote branches
  of `refs` are up to date.

## Value

The items of the list (`reports/<book>` and `presentations/<name>`),
invisibly.

## Details

    render:
      parallel:
        matrix:
          - ITEM:
              - reports/01_first_fr
              - presentations/seminar

Only the lines of the items are replaced: the rest of the file, comments
included, is kept. The items can be listed on several lines (`- item`)
or on the line of the variable (`- ITEM: [a, b]`); the result is always
the former. The list has the books and presentations of the working
directory and of the branches `refs` (read with git, without checking
them out), so that a job of the matrix exists for the items of every
branch built by the CI: a job whose item is not on its branch has
nothing to render.

## Examples

``` r
if (FALSE) { # \dontrun{
update_gitlab_ci()
} # }
```
