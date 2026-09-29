test_that("the default template is shipped with the package", {
  local_book_env()
  templates <- list_templates_book()
  expect_true("default" %in% templates$name[templates$source == "package"])
})

test_that("create_template_book saves a template usable by create_book", {
  dir <- local_book_env()
  suppressMessages(create_book("modele", path = dir, title = "Modele"))
  writeLines("# Methodes", file.path(dir, "modele", "methodes.qmd"))
  dir.create(file.path(dir, "modele", "_book"))
  writeLines("x", file.path(dir, "modele", "_book", "index.html"))

  expect_message(
    path <- create_template_book("mon_modele", from = file.path(dir, "modele")),
    "mon_modele"
  )
  expect_true(file.exists(file.path(path, "methodes.qmd")))
  expect_false(dir.exists(file.path(path, "_book")))
  expect_true("mon_modele" %in% list_templates_book()$name)

  suppressMessages(create_book("nouveau", path = dir, template = "mon_modele"))
  expect_true(file.exists(file.path(dir, "nouveau", "methodes.qmd")))
  config <- yaml::read_yaml(file.path(dir, "nouveau", "_quarto.yml"))
  expect_equal(config$book$title, "nouveau")

  expect_error(create_template_book("mon_modele"), "already exists")
  suppressMessages(create_template_book("mon_modele", overwrite = TRUE))
  expect_false(file.exists(file.path(path, "methodes.qmd")))

  expect_true(remove_template_book("mon_modele"))
  expect_false("mon_modele" %in% list_templates_book()$name)
  expect_error(remove_template_book("mon_modele"), "No user template")
})

test_that("a user template can override the package default", {
  dir <- local_book_env()
  path <- suppressMessages(create_template_book("default"))
  cat("lang: en\n", file = file.path(path, "_quarto.yml"), append = TRUE)
  expect_equal(resolve_template("default"), path)
})

test_that("template names and folders are validated", {
  dir <- local_book_env()
  expect_error(create_template_book("../x"), "letters")
  expect_error(create_template_book("x", from = dir), "_quarto.yml")
})
