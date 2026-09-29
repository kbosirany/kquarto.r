test_that("create_book creates folders and a filled _quarto.yml", {
  dir <- local_book_env()
  expect_message(
    paths <- create_book(
      c("rapport_a", "rapport_b"),
      path = dir, author = c("A", "B"), lang = "en"
    ),
    "rapport_a, rapport_b"
  )

  expect_length(paths, 2)
  index <- file.path(dir, c("rapport_a", "rapport_b"), "index.qmd")
  expect_true(all(file.exists(index)))

  config <- read_config(dir, "rapport_a")
  expect_equal(config$project$type, "book")
  expect_equal(config$project$`output-dir`, "_book")
  expect_equal(config$book$title, "rapport_a")
  expect_equal(unlist(config$book$author), c("A", "B"))
  expect_equal(config$lang, "en")

  gitignore <- readLines(file.path(dir, "rapport_a", ".gitignore"))
  expect_true("/_book/" %in% gitignore)
})

test_that("titles can be named, unnamed or default to folder names", {
  dir <- local_book_env()
  suppressMessages(create_book(
    c("a", "b"), path = dir, title = c(b = "Titre B")
  ))
  expect_equal(read_config(dir, "a")$book$title, "a")
  expect_equal(read_config(dir, "b")$book$title, "Titre B")

  suppressMessages(create_book(c("c", "d"), path = dir, title = c("C", "D")))
  expect_equal(read_config(dir, "d")$book$title, "D")

  expect_error(create_book(c("e", "f"), path = dir, title = "E"), "same length")
  expect_error(create_book("g", path = dir, title = c(zzz = "Z")), "zzz")
})

test_that("extra fields are merged and booleans stay YAML 1.2", {
  dir <- local_book_env()
  suppressMessages(create_book(
    "r", path = dir,
    format = list(html = list(theme = "flatly", `code-fold` = TRUE))
  ))
  lines <- readLines(file.path(dir, "r", "_quarto.yml"))
  expect_true(any(grepl("code-fold: true", lines, fixed = TRUE)))
  expect_false(any(grepl(": yes$", lines)))

  config <- read_config(dir, "r")
  expect_equal(config$format$html$theme, "flatly")
  expect_true(config$format$html$toc)

  expect_error(
    create_book(
      "s", path = dir, title = "S", author = NULL, lang = "fr",
      date = NULL, template = "default", output_dir = "_book",
      chapters = NULL, chapter_prefix = NULL, list(1)
    ),
    "named"
  )
})

test_that("existing _quarto.yml is protected unless overwrite = TRUE", {
  dir <- local_book_env()
  suppressMessages(create_book("r", path = dir, title = "Ancien"))
  writeLines("mon texte", file.path(dir, "r", "index.qmd"))

  expect_error(create_book("r", path = dir, title = "Nouveau"), "overwrite")
  expect_equal(read_config(dir, "r")$book$title, "Ancien")

  suppressMessages(
    create_book("r", path = dir, title = "Nouveau", overwrite = TRUE)
  )
  expect_equal(read_config(dir, "r")$book$title, "Nouveau")
})

test_that("report folders are added to .Rbuildignore in a package", {
  dir <- local_book_env()
  writeLines("Package: test", file.path(dir, "DESCRIPTION"))
  suppressMessages(create_book(c("reports/rapport.v1", "note"), path = dir))
  suppressMessages(
    create_book("reports/rapport.v1", path = dir, overwrite = TRUE)
  )

  ignore <- readLines(file.path(dir, ".Rbuildignore"))
  expect_equal(ignore, c("^reports/rapport\\.v1$", "^note$"))
})

test_that("invalid inputs are rejected", {
  dir <- local_book_env()
  expect_error(create_book(character(), path = dir), "non-empty")
  expect_error(create_book(c("a", "a"), path = dir), "duplicated")
  expect_error(
    create_book("a", path = file.path(dir, "nope")),
    "does not exist"
  )
  expect_error(
    create_book("a", path = dir, template = "nope"),
    "Unknown template"
  )
})

test_that("list_books finds book folders", {
  dir <- local_book_env()
  suppressMessages(create_book(c("a", "b", "sub/c"), path = dir))
  dir.create(file.path(dir, "autre"))
  expect_setequal(list_books(dir), c("a", "b"))
  expect_setequal(list_books(dir, recursive = TRUE), c("a", "b", "sub/c"))
})
