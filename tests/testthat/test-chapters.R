test_that("chapter prefix follows the book language", {
  expect_equal(chapter_prefix("fr"), "chapitre")
  expect_equal(chapter_prefix("fr-FR"), "chapitre")
  expect_equal(chapter_prefix("en"), "chapter")
  expect_equal(chapter_prefix(NULL), "chapter")
  expect_equal(chapter_prefix("fro"), "chapter")
})

test_that("slugify builds clean file names", {
  expect_equal(slugify("Matériel et méthodes"), "materiel-et-methodes")
  expect_equal(slugify("  Résultats (2025) !"), "resultats-2025")
})

test_that("create_book creates numbered chapters after index.qmd", {
  dir <- local_book_env()
  suppressMessages(create_book(
    c("fr_book", "en_book"), path = dir,
    chapters = c("Introduction", "Méthodes")
  ))
  expect_true(file.exists(file.path(dir, "fr_book", "chapitre-01-introduction.qmd")))
  expect_true(file.exists(file.path(dir, "fr_book", "chapitre-02-methodes.qmd")))
  expect_equal(
    readLines(file.path(dir, "fr_book", "chapitre-02-methodes.qmd"))[[1]],
    "# Méthodes"
  )
  config <- yaml::read_yaml(file.path(dir, "fr_book", "_quarto.yml"))
  expect_equal(
    unlist(config$book$chapters),
    c("index.qmd", "chapitre-01-introduction.qmd", "chapitre-02-methodes.qmd")
  )
  expect_equal(readLines(file.path(dir, "fr_book", "index.qmd"))[[1]],
               "# Introduction {.unnumbered}")

  suppressMessages(create_book("en", path = dir, lang = "en-GB", chapters = "Results"))
  expect_true(file.exists(file.path(dir, "en", "chapter-01-results.qmd")))

  suppressMessages(create_book("custom", path = dir, chapters = "A", chapter_prefix = "partie"))
  expect_true(file.exists(file.path(dir, "custom", "partie-01-a.qmd")))
})

test_that("create_book_chapter increments the highest existing number", {
  dir <- local_book_env()
  suppressMessages(create_book("r", path = dir))
  file.create(file.path(dir, "r", "chapitre-07-ancien.qmd"))

  path <- suppressMessages(create_book_chapter("r", "Discussion", path = dir, title = "Discussion générale"))
  expect_equal(basename(path), "chapitre-08-discussion.qmd")
  expect_equal(readLines(path)[[1]], "# Discussion générale")

  expect_message(create_book_chapter("r", "Conclusion", path = dir), "chapitre-09-conclusion")
  config <- yaml::read_yaml(file.path(dir, "r", "_quarto.yml"))
  expect_equal(utils::tail(unlist(config$book$chapters), 2),
               c("chapitre-08-discussion.qmd", "chapitre-09-conclusion.qmd"))
})

test_that("create_book_chapter validates its inputs", {
  dir <- local_book_env()
  expect_error(create_book_chapter("nope", "a", path = dir), "create_book")
  suppressMessages(create_book("r", path = dir))
  expect_error(create_book_chapter("r", "", path = dir), "non-empty")
  expect_error(create_book_chapter("r", "!!", path = dir), "letter or digit")
  expect_error(create_book("s", path = dir, chapters = 1), "character")
})

test_that("overwrite keeps the existing chapters", {
  dir <- local_book_env()
  suppressMessages(create_book("r", path = dir, chapters = c("A", "B")))
  unlink(file.path(dir, "r", "chapitre-02-b.qmd"))
  suppressMessages(create_book("r", path = dir, title = "Nouveau", overwrite = TRUE))
  config <- yaml::read_yaml(file.path(dir, "r", "_quarto.yml"))
  expect_equal(config$book$title, "Nouveau")
  expect_equal(unlist(config$book$chapters), c("index.qmd", "chapitre-01-a.qmd"))
  expect_true(file.exists(file.path(dir, "r", "chapitre-01-a.qmd")))
})

test_that("create_book does not duplicate existing chapters", {
  dir <- local_book_env()
  suppressMessages(create_book("r", path = dir, chapters = c("A", "B")))
  suppressMessages(create_book("r", path = dir, chapters = c("A", "C"), overwrite = TRUE))
  expect_setequal(
    list.files(file.path(dir, "r"), pattern = "^chapitre"),
    c("chapitre-01-a.qmd", "chapitre-02-b.qmd", "chapitre-03-c.qmd")
  )
  config <- yaml::read_yaml(file.path(dir, "r", "_quarto.yml"))
  expect_equal(
    unlist(config$book$chapters),
    c("index.qmd", "chapitre-01-a.qmd", "chapitre-02-b.qmd", "chapitre-03-c.qmd")
  )
})

test_that("slugify handles French ligatures and cedillas", {
  expect_equal(slugify("État des cœurs à la façon"), "etat-des-coeurs-a-la-facon")
})
