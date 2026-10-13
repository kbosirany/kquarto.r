# Extracted from test-presentations.R:42

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "kquarto.r", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
dir <- local_book_env()
files <- suppressMessages(create_presentation(
    c("a", "b"),
    path = dir,
    title = c(b = "Séminaire B"),
    author = "Kevin Orlando",
    subtitle = "Sous-titre",
    template = "inrae-presentation"
  ))
expect_equal(basename(files), c("a.qmd", "b.qmd"))
expect_true(file.exists(file.path(dir, "b", "inrae-charte.scss")))
expect_true(file.exists(file.path(dir, "b", "inrae-slides.scss")))
expect_true(file.exists(file.path(dir, "b", "images", "logo-inrae.png")))
expect_false(file.exists(file.path(dir, "b", "slides.qmd")))
expect_false(file.exists(file.path(dir, "b", "template.yml")))
header <- read_slides(files[[2]])$header
expect_equal(header$title, "Séminaire B")
expect_equal(header$author, "Kevin Orlando")
expect_equal(header$lang, "fr")
expect_true(header$format$revealjs$`slide-number`)
