test_that("update_pkgdown_yml writes one menu, a header by language", {
  dir <- local_book_env()
  suppressMessages(create_book(
    c("a-fr", "b-fr", "a-en"),
    path = dir,
    title = c("A", "B", "A en")
  ))
  file <- file.path(dir, "_pkgdown.yml")
  writeLines(c("url: https://example.org", "navbar:", "  structure:",
               "    left: [intro, reports_fr, news]"), file)

  update_pkgdown_yml(path = dir, pkgdown_file = file)
  config <- yaml::read_yaml(file)
  expect_equal(config$url, "https://example.org")
  expect_equal(config$navbar$structure$left, c("intro", "news", "reports"))
  expect_equal(config$navbar$components$reports$text, "Reports")
  menu <- config$navbar$components$reports$menu
  expect_equal(
    vapply(menu, function(x) x$text, ""),
    c("English", "A en", "---------", "Fran\u00e7ais", "A", "B")
  )
  expect_equal(menu[[6]]$href, "reports/b-fr/index.html")
  expect_null(menu[[1]]$href)

  # idempotent
  update_pkgdown_yml(path = dir, pkgdown_file = file)
  expect_equal(yaml::read_yaml(file), config)

  update_pkgdown_yml("a-fr", path = dir, titles = "Mon A", pkgdown_file = file)
  menu <- yaml::read_yaml(file)$navbar$components$reports$menu
  expect_length(menu, 1)
  expect_equal(menu[[1]]$text, "Mon A")
})

test_that("update_pkgdown_yml errors without book", {
  dir <- local_book_env()
  expect_error(update_pkgdown_yml(path = dir), "No Quarto book")
})

test_that("build_site renders the books then builds the site", {
  dir <- local_book_env()
  suppressMessages(create_book("a-fr", path = dir))
  withr::local_dir(dir)
  calls <- list()
  local_mocked_bindings(
    render_book = function(dirname_reports, path, output_dir, ...) {
      calls[[length(calls) + 1]] <<- list(dirname_reports, output_dir)
    },
    .package = "kquarto.r"
  )
  local_mocked_bindings(
    pkgdown_init_site = function(...) NULL,
    pkgdown_build_site = function(...) "built"
  )
  build_site(path = ".", dest = "public")
  expect_length(calls, 1)
  expect_equal(calls[[1]][[1]], "a-fr")
  # normalizePath() uses backslashes on Windows
  expect_match(calls[[1]][[2]], "public[/\\\\]reports[/\\\\]a-fr$")
  expect_true(file.exists("_pkgdown.yml"))
})

test_that("update_pkgdown_yml adds a menu for the presentations", {
  dir <- local_book_env()
  suppressMessages(create_book("a-fr", path = dir, title = "A"))
  pres <- file.path(dir, "presentations")
  dir.create(pres)
  suppressMessages(create_presentation(
    c("point", "bilan"),
    path = pres,
    title = c(point = "Point d'étape", bilan = "Bilan")
  ))
  file <- file.path(dir, "_pkgdown.yml")
  writeLines(c("navbar:", "  structure:", "    left: [intro, news]"), file)

  update_pkgdown_yml(
    path = dir, pkgdown_file = file, presentations_path = pres
  )
  config <- yaml::read_yaml(file)
  expect_equal(
    config$navbar$structure$left, c("intro", "news", "reports", "presentations")
  )
  expect_equal(config$navbar$components$presentations$text, "Presentations")
  menu <- config$navbar$components$presentations$menu
  expect_equal(
    vapply(menu, function(x) x$text, ""), c("Bilan", "Point d'étape")
  )
  expect_equal(menu[[1]]$href, "presentations/bilan/index.html")
  expect_equal(config$navbar$components$reports$menu[[1]]$text, "A")

  # idempotent
  update_pkgdown_yml(
    path = dir, pkgdown_file = file, presentations_path = pres
  )
  expect_equal(yaml::read_yaml(file), config)

  # no more presentation: the menu is removed
  unlink(pres, recursive = TRUE)
  update_pkgdown_yml(
    path = dir, pkgdown_file = file, presentations_path = pres
  )
  config <- yaml::read_yaml(file)
  expect_null(config$navbar$components$presentations)
  expect_false("presentations" %in% config$navbar$structure$left)
})

test_that("the presentations menu has a header by language", {
  dir <- local_book_env()
  suppressMessages(create_presentation(
    c("20261020-point-fr", "20261105-point-en", "20261020-bilan-fr"),
    path = dir,
    title = c("Point", "Review", "Bilan")
  ))
  file <- file.path(dir, "_pkgdown.yml")

  update_pkgdown_yml(
    path = file.path(dir, "none"), pkgdown_file = file,
    presentations_path = dir
  )
  menu <- yaml::read_yaml(file)$navbar$components$presentations$menu
  expect_equal(
    vapply(menu, function(x) x$text, ""),
    c("English", "Review", "---------", "Fran\u00e7ais", "Bilan", "Point")
  )
  expect_equal(menu[[2]]$href, "presentations/20261105-point-en/index.html")
})

test_that("update_pkgdown_yml works with presentations only", {
  dir <- local_book_env()
  suppressMessages(create_presentation("point", path = dir, title = "Point"))
  file <- file.path(dir, "_pkgdown.yml")
  empty <- file.path(dir, "no-reports")

  update_pkgdown_yml(
    path = empty, pkgdown_file = file, presentations_path = dir
  )
  config <- yaml::read_yaml(file)
  expect_null(config$navbar$components$reports)
  expect_equal(config$navbar$structure$left, "presentations")
})

test_that("build_site renders the presentations in the site", {
  dir <- local_book_env()
  dir.create(file.path(dir, "reports"))
  dir.create(file.path(dir, "presentations"))
  suppressMessages(create_book("a-fr", path = file.path(dir, "reports")))
  suppressMessages(create_presentation(
    "point", path = file.path(dir, "presentations"), title = "Point"
  ))
  withr::local_dir(dir)
  rendered <- list()
  local_mocked_bindings(
    render_book = function(...) NULL,
    render_presentation = function(name, path, output_dir, ...) {
      rendered[[length(rendered) + 1]] <<- list(name, path, output_dir)
    },
    .package = "kquarto.r"
  )
  local_mocked_bindings(
    pkgdown_init_site = function(...) NULL,
    pkgdown_build_site = function(...) "built"
  )
  expect_equal(build_site(path = "reports", dest = "public"), "built")
  expect_length(rendered, 1)
  expect_equal(rendered[[1]][[1]], "point")
  expect_match(rendered[[1]][[3]], "public[/\\\\]presentations$")
  config <- yaml::read_yaml("_pkgdown.yml")
  expect_equal(
    config$navbar$components$presentations$menu[[1]]$href,
    "presentations/point/index.html"
  )
})

test_that("the menus have a header by category, Package then Others", {
  dir <- local_book_env()
  suppressMessages(create_book(
    c("02-calib-fr", "01-data-fr", "rapport-fr", "01-data-en"),
    path = dir,
    title = c("Calib", "Data", "Rapport", "Data en")
  ))
  file <- file.path(dir, "_pkgdown.yml")

  update_pkgdown_yml(path = dir, pkgdown_file = file)
  menu <- yaml::read_yaml(file)$navbar$components$reports$menu
  expect_equal(
    vapply(menu, function(x) x$text, ""),
    c("Package [en]", "Data en", "---------", "Package [fr]", "Data",
      "Calib", "---------", "Others [fr]", "Rapport")
  )

  # the category key of _quarto.yml overrides the folder name
  yml <- file.path(dir, "rapport-fr", "_quarto.yml")
  base <- readLines(yml)
  writeLines(c(base, "category: package"), yml)
  update_pkgdown_yml(path = dir, pkgdown_file = file)
  menu <- yaml::read_yaml(file)$navbar$components$reports$menu
  expect_equal(
    vapply(menu, function(x) x$text, ""),
    c("English", "Data en", "---------", "Français", "Data", "Calib",
      "Rapport")
  )

  writeLines(c(base, "category: meeting"), yml)
  expect_error(
    update_pkgdown_yml(path = dir, pkgdown_file = file),
    "must be 'package' or 'others'"
  )
})

test_that("the presentations menu has Package, then Others by date", {
  dir <- local_book_env()
  suppressMessages(create_presentation(
    c("01-data-fr", "20260902-point-fr", "20261020-copil-fr", "atelier-fr"),
    path = dir,
    title = c("Data", "Point", "Copil", "Atelier")
  ))
  file <- file.path(dir, "_pkgdown.yml")

  update_pkgdown_yml(
    path = file.path(dir, "none"), pkgdown_file = file,
    presentations_path = dir
  )
  menu <- yaml::read_yaml(file)$navbar$components$presentations$menu
  expect_equal(
    vapply(menu, function(x) x$text, ""),
    c("Package", "Data", "---------", "Others", "Copil", "Point", "Atelier")
  )
})

test_that("menu_category classifies by folder name", {
  expect_equal(
    menu_category(c("01-a", "20261020-b", "c", "1-d")),
    c("package", "others", "others", "package")
  )
  expect_equal(
    menu_category(c("01-a", "b"), list("Others", NULL)),
    c("others", "others")
  )
})
