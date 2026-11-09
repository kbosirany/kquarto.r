ci_lines <- c(
  "# comment",
  "render:",
  "  parallel:",
  "    matrix:",
  "      - ITEM:",
  "          - reports/old",
  "          - reports/older",
  "  script:",
  "    - echo \"$ITEM\"",
  ""
)

test_that("update_gitlab_ci replaces the items and keeps the rest", {
  dir <- local_book_env()
  withr::local_dir(dir)
  dir.create("reports")
  dir.create("presentations")
  suppressMessages(create_book(c("b_fr", "a_fr")))
  suppressMessages(create_presentation("seminar"))
  writeLines(ci_lines, ".gitlab-ci.yml")
  local_mocked_bindings(
    git_files = function(ref) {
      if (ref == "origin/dev") {
        c("reports/c_fr/_quarto.yml", "reports/d_site/_quarto.yml",
          "reports/b_fr/_quarto.yml")
      } else {
        character()
      }
    },
    git_show = function(ref, file) {
      if (grepl("d_site", file)) {
        "project:\n  type: website"
      } else {
        "project:\n  type: book"
      }
    }
  )
  items <- suppressMessages(update_gitlab_ci())
  expect_equal(
    items,
    c("reports/a_fr", "reports/b_fr", "reports/c_fr",
      "presentations/seminar")
  )
  lines <- readLines(".gitlab-ci.yml")
  expect_equal(lines[1:5], ci_lines[1:5])
  expect_equal(lines[6:9], paste0("          - ", items))
  expect_equal(lines[10:12], ci_lines[8:10])
  # idempotent
  suppressMessages(update_gitlab_ci())
  expect_equal(readLines(".gitlab-ci.yml"), lines)
})

test_that("update_gitlab_ci does not touch the file without item", {
  dir <- local_book_env()
  withr::local_dir(dir)
  writeLines(ci_lines, ".gitlab-ci.yml")
  expect_message(update_gitlab_ci(refs = NULL), "not changed")
  expect_equal(readLines(".gitlab-ci.yml"), ci_lines)
})

test_that("update_gitlab_ci errors without file or matrix", {
  dir <- local_book_env()
  withr::local_dir(dir)
  expect_error(update_gitlab_ci(), "No such file")
  dir.create("reports")
  suppressMessages(create_book("a_fr"))
  writeLines(c("render:", "  script: echo"), ".gitlab-ci.yml")
  expect_error(update_gitlab_ci(refs = NULL), "Expected one `- ITEM:`")
})

test_that("update_gitlab_ci replaces items written in flow style", {
  dir <- local_book_env()
  withr::local_dir(dir)
  dir.create("reports")
  suppressMessages(create_book(c("a_fr", "b_fr")))
  writeLines(sub(
    "ITEM:", "ITEM: [reports/old, reports/older]",
    ci_lines[!grepl("old", ci_lines)], fixed = TRUE
  ), ".gitlab-ci.yml")
  suppressMessages(update_gitlab_ci(refs = NULL))
  lines <- readLines(".gitlab-ci.yml")
  expect_equal(lines[1:5], ci_lines[1:5])
  expect_equal(
    lines[5:7], c("      - ITEM:", "          - reports/a_fr",
                  "          - reports/b_fr")
  )
  expect_equal(lines[8:10], ci_lines[8:10])
})

test_that("update_gitlab_ci fetches the remote branches on request", {
  dir <- local_book_env()
  withr::local_dir(dir)
  dir.create("reports")
  suppressMessages(create_book("a_fr"))
  writeLines(ci_lines, ".gitlab-ci.yml")
  fetched <- 0
  local_mocked_bindings(git_fetch = function() fetched <<- fetched + 1)
  suppressMessages(update_gitlab_ci(refs = NULL))
  expect_equal(fetched, 0)
  suppressMessages(update_gitlab_ci(refs = NULL, fetch = TRUE))
  expect_equal(fetched, 1)
})
