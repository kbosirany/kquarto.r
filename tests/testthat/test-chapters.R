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
    c("fr_book", "en_book"), path_reports = dir,
    chapters = c("Introduction", "Méthodes")
  ))
  fr_book <- file.path(dir, "fr_book")
  expect_true(file.exists(file.path(fr_book, "chapitre_01_introduction.qmd")))
  expect_true(file.exists(file.path(fr_book, "chapitre_02_methodes.qmd")))
  expect_equal(
    readLines(file.path(dir, "fr_book", "chapitre_02_methodes.qmd"))[[1]],
    "# Méthodes"
  )
  config <- read_config(dir, "fr_book")
  expect_equal(
    unlist(config$book$chapters),
    c("index.qmd", "chapitre_01_introduction.qmd", "chapitre_02_methodes.qmd")
  )
  expect_equal(readLines(file.path(dir, "fr_book", "index.qmd"))[[1]],
               "# Introduction {.unnumbered}")

  suppressMessages(
    create_book("en", path_reports = dir, lang = "en-GB", chapters = "Results")
  )
  expect_true(file.exists(file.path(dir, "en", "chapter_01_results.qmd")))

  suppressMessages(create_book(
    "custom", path_reports = dir, chapters = "A", chapter_prefix = "partie"
  ))
  expect_true(file.exists(file.path(dir, "custom", "partie_01_a.qmd")))
})

test_that("create_book_chapter increments the highest existing number", {
  dir <- local_book_env()
  suppressMessages(create_book("r", path_reports = dir))
  file.create(file.path(dir, "r", "chapitre-07-ancien.qmd"))

  path <- suppressMessages(create_book_chapter(
    "r", "Discussion", path_reports = dir, title = "Discussion générale"
  ))
  expect_equal(basename(path), "chapitre_08_discussion.qmd")
  expect_equal(readLines(path)[[1]], "# Discussion générale")

  expect_message(
    create_book_chapter("r", "Conclusion", path_reports = dir),
    "chapitre_09_conclusion"
  )
  config <- read_config(dir, "r")
  expect_equal(utils::tail(unlist(config$book$chapters), 2),
               c("chapitre_08_discussion.qmd", "chapitre_09_conclusion.qmd"))
})

test_that("create_book_chapter validates its inputs", {
  dir <- local_book_env()
  expect_error(create_book_chapter(
    "nope", "a", path_reports = dir
  ), "create_book")
  suppressMessages(create_book("r", path_reports = dir))
  expect_error(create_book_chapter("r", "", path_reports = dir), "non-empty")
  expect_error(create_book_chapter(
    "r", "!!", path_reports = dir
  ), "letter or digit")
  expect_error(create_book("s", path_reports = dir, chapters = 1), "character")
})

test_that("overwrite keeps the existing chapters", {
  dir <- local_book_env()
  suppressMessages(create_book("r", path_reports = dir, chapters = c("A", "B")))
  unlink(file.path(dir, "r", "chapitre_02_b.qmd"))
  suppressMessages(
    create_book("r", path_reports = dir, title = "Nouveau", overwrite = TRUE)
  )
  config <- read_config(dir, "r")
  expect_equal(config$book$title, "Nouveau")
  expect_equal(
    unlist(config$book$chapters),
    c("index.qmd", "chapitre_01_a.qmd")
  )
  expect_true(file.exists(file.path(dir, "r", "chapitre_01_a.qmd")))
})

test_that("create_book does not duplicate existing chapters", {
  dir <- local_book_env()
  suppressMessages(create_book("r", path_reports = dir, chapters = c("A", "B")))
  suppressMessages(create_book(
    "r", path_reports = dir, chapters = c("A", "C"), overwrite = TRUE
  ))
  expect_setequal(
    list.files(file.path(dir, "r"), pattern = "^chapitre"),
    c("chapitre_01_a.qmd", "chapitre_02_b.qmd", "chapitre_03_c.qmd")
  )
  config <- read_config(dir, "r")
  expect_equal(
    unlist(config$book$chapters),
    c(
      "index.qmd", "chapitre_01_a.qmd", "chapitre_02_b.qmd",
      "chapitre_03_c.qmd"
    )
  )
})

test_that("slugify handles French ligatures and cedillas", {
  expect_equal(
    slugify("État des cœurs à la façon"),
    "etat-des-coeurs-a-la-facon"
  )
})
