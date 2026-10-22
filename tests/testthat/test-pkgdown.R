test_that("update_pkgdown_yml writes one menu, a header by language", {
  dir <- local_book_env()
  suppressMessages(create_book(
    c("a_fr", "b_fr", "a_en"),
    path_reports = dir,
    title = c("A", "B", "A en")
  ))
  file <- file.path(dir, "_pkgdown.yml")
  writeLines(c("url: https://example.org", "navbar:", "  structure:",
               "    left: [intro, reports_fr, news]"), file)

  update_pkgdown_yml(path_reports = dir, pkgdown_file = file)
  config <- yaml::read_yaml(file)
  expect_equal(config$url, "https://example.org")
  expect_equal(config$navbar$structure$left, c("intro", "news", "reports"))
  expect_equal(config$navbar$components$reports$text, "Reports")
  menu <- config$navbar$components$reports$menu
  expect_equal(
    vapply(menu, function(x) x$text, ""),
    c("English", "A en", "---------", "Fran\u00e7ais", "A", "B")
  )
  expect_equal(menu[[6]]$href, "reports/b_fr/index.html")
  expect_null(menu[[1]]$href)

  # idempotent
  update_pkgdown_yml(path_reports = dir, pkgdown_file = file)
  expect_equal(yaml::read_yaml(file), config)

  update_pkgdown_yml(
    "a_fr", path_reports = dir, titles = "Mon A", pkgdown_file = file
  )
  menu <- yaml::read_yaml(file)$navbar$components$reports$menu
  expect_length(menu, 1)
  expect_equal(menu[[1]]$text, "Mon A")
})

test_that("update_pkgdown_yml errors without book", {
  dir <- local_book_env()
  expect_error(update_pkgdown_yml(path_reports = dir), "No Quarto book")
})

test_that("build_site renders the books then builds the site", {
  dir <- local_book_env()
  suppressMessages(create_book("a_fr", path_reports = dir))
  withr::local_dir(dir)
  calls <- list()
  local_mocked_bindings(
    run_renders = function(renders, workers) {
      calls <<- c(calls, lapply(renders, function(x) {
        list(x$label, render_output_dir(x))
      }))
    },
    .package = "kquarto.r"
  )
  local_mocked_bindings(
    pkgdown_init_site = function(...) NULL,
    pkgdown_build_site = function(...) "built",
    pkgdown_dst_path = function(override) override$destination
  )
  build_site(path_reports = ".", path_site = "public")
  expect_length(calls, 1)
  expect_equal(calls[[1]][[1]], "a_fr")
  # normalizePath() uses backslashes on Windows
  expect_match(calls[[1]][[2]], "public[/\\\\]reports[/\\\\]a_fr$")
  expect_true(file.exists("_pkgdown.yml"))
})

test_that("update_pkgdown_yml adds a menu for the presentations", {
  dir <- local_book_env()
  suppressMessages(create_book("a_fr", path_reports = dir, title = "A"))
  pres <- file.path(dir, "presentations")
  dir.create(pres)
  suppressMessages(create_presentation(
    c("point", "bilan"),
    path_presentations = pres,
    title = c(point = "Point d'étape", bilan = "Bilan")
  ))
  file <- file.path(dir, "_pkgdown.yml")
  writeLines(c("navbar:", "  structure:", "    left: [intro, news]"), file)

  update_pkgdown_yml(
    path_reports = dir, pkgdown_file = file, path_presentations = pres
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
    path_reports = dir, pkgdown_file = file, path_presentations = pres
  )
  expect_equal(yaml::read_yaml(file), config)

  # no more presentation: the menu is removed
  unlink(pres, recursive = TRUE)
  update_pkgdown_yml(
    path_reports = dir, pkgdown_file = file, path_presentations = pres
  )
  config <- yaml::read_yaml(file)
  expect_null(config$navbar$components$presentations)
  expect_false("presentations" %in% config$navbar$structure$left)
})

test_that("the presentations menu has a header by language", {
  dir <- local_book_env()
  suppressMessages(create_presentation(
    c("20261020_point_fr", "20261105_point_en", "20261020_bilan_fr"),
    path_presentations = dir,
    title = c("Point", "Review", "Bilan")
  ))
  file <- file.path(dir, "_pkgdown.yml")

  update_pkgdown_yml(
    path_reports = file.path(dir, "none"), pkgdown_file = file,
    path_presentations = dir
  )
  menu <- yaml::read_yaml(file)$navbar$components$presentations$menu
  expect_equal(
    vapply(menu, function(x) x$text, ""),
    c("English", "Review", "---------", "Fran\u00e7ais", "Bilan", "Point")
  )
  expect_equal(menu[[2]]$href, "presentations/20261105_point_en/index.html")
})

test_that("update_pkgdown_yml works with presentations only", {
  dir <- local_book_env()
  suppressMessages(create_presentation(
    "point", path_presentations = dir, title = "Point"
  ))
  file <- file.path(dir, "_pkgdown.yml")
  empty <- file.path(dir, "no-reports")

  update_pkgdown_yml(
    path_reports = empty, pkgdown_file = file, path_presentations = dir
  )
  config <- yaml::read_yaml(file)
  expect_null(config$navbar$components$reports)
  expect_equal(config$navbar$structure$left, "presentations")
})

test_that("build_site renders the presentations in the site", {
  dir <- local_book_env()
  dir.create(file.path(dir, "reports"))
  dir.create(file.path(dir, "presentations"))
  suppressMessages(create_book(
    "a_fr", path_reports = file.path(dir, "reports")
  ))
  suppressMessages(create_presentation(
    "point",
    path_presentations = file.path(dir, "presentations"),
    title = "Point"
  ))
  withr::local_dir(dir)
  rendered <- list()
  local_mocked_bindings(
    run_renders = function(renders, workers) {
      rendered <<- renders
      mock_render_slides(renders)
    },
    .package = "kquarto.r"
  )
  local_mocked_bindings(
    pkgdown_init_site = function(...) NULL,
    pkgdown_build_site = function(...) "built",
    pkgdown_dst_path = function(override) override$destination
  )
  expect_equal(
    build_site(path_reports = "reports", path_site = "public"), "built"
  )
  # the book and the presentation in the same queue
  expect_equal(
    vapply(rendered, function(x) x$label, ""), c("a_fr", "point")
  )
  expect_true(file.exists("public/presentations/point/index.html"))
  config <- yaml::read_yaml("_pkgdown.yml")
  expect_equal(
    config$navbar$components$presentations$menu[[1]]$href,
    "presentations/point/index.html"
  )
})

test_that("build_site renders the books or the presentations only", {
  dir <- local_book_env()
  dir.create(file.path(dir, "reports"))
  dir.create(file.path(dir, "presentations"))
  suppressMessages(create_book(
    "a_fr", path_reports = file.path(dir, "reports")
  ))
  suppressMessages(create_presentation(
    "point",
    path_presentations = file.path(dir, "presentations"),
    title = "Point"
  ))
  withr::local_dir(dir)
  rendered <- character()
  local_mocked_bindings(
    run_renders = function(renders, workers) {
      rendered <<- c(rendered, vapply(renders, function(x) x$label, ""))
      mock_render_slides(renders)
    },
    .package = "kquarto.r"
  )
  inits <- 0
  local_mocked_bindings(
    pkgdown_init_site = function(...) inits <<- inits + 1,
    pkgdown_build_site = function(...) "built",
    pkgdown_dst_path = function(override) override$destination
  )

  build_site(render_presentations = FALSE)
  expect_equal(rendered, "a_fr")
  # the menu of the presentations not rendered is kept
  config <- yaml::read_yaml("_pkgdown.yml")
  expect_equal(
    config$navbar$components$presentations$menu[[1]]$href,
    "presentations/point/index.html"
  )
  expect_equal(config$navbar$structure$left, c("reports", "presentations"))

  rendered <- character()
  build_site(render_reports = FALSE)
  expect_equal(rendered, "point")
  expect_equal(yaml::read_yaml("_pkgdown.yml"), config)

  # neither: the books and presentations rendered elsewhere (e.g. other CI
  # jobs) are only added to the navbar
  unlink("_pkgdown.yml")
  rendered <- character()
  expect_equal(
    build_site(render_reports = FALSE, render_presentations = FALSE), "built"
  )
  expect_length(rendered, 0)
  expect_equal(yaml::read_yaml("_pkgdown.yml"), config)
  # pkgdown recognises the site folder, filled by the other jobs
  expect_equal(inits, 3)
})

test_that("the menus have a header by category, Package then Others", {
  dir <- local_book_env()
  suppressMessages(create_book(
    c("02_calib_fr", "01_data_fr", "rapport_fr", "01_data_en"),
    path_reports = dir,
    title = c("Calib", "Data", "Rapport", "Data en")
  ))
  file <- file.path(dir, "_pkgdown.yml")

  update_pkgdown_yml(path_reports = dir, pkgdown_file = file)
  menu <- yaml::read_yaml(file)$navbar$components$reports$menu
  expect_equal(
    vapply(menu, function(x) x$text, ""),
    c("Package [en]", "Data en", "---------", "Package [fr]", "Data",
      "Calib", "---------", "Others [fr]", "Rapport")
  )

  # the category key of _quarto.yml overrides the folder name
  yml <- file.path(dir, "rapport_fr", "_quarto.yml")
  base <- readLines(yml)
  writeLines(c(base, "category: package"), yml)
  update_pkgdown_yml(path_reports = dir, pkgdown_file = file)
  menu <- yaml::read_yaml(file)$navbar$components$reports$menu
  expect_equal(
    vapply(menu, function(x) x$text, ""),
    c("English", "Data en", "---------", "Français", "Data", "Calib",
      "Rapport")
  )

  writeLines(c(base, "category: meeting"), yml)
  expect_error(
    update_pkgdown_yml(path_reports = dir, pkgdown_file = file),
    "must be 'package' or 'others'"
  )
})

test_that("the presentations menu has Package, then Others by date", {
  dir <- local_book_env()
  suppressMessages(create_presentation(
    c("01_data_fr", "20260902_point_fr", "20261020_copil_fr", "atelier_fr"),
    path_presentations = dir,
    title = c("Data", "Point", "Copil", "Atelier")
  ))
  file <- file.path(dir, "_pkgdown.yml")

  update_pkgdown_yml(
    path_reports = file.path(dir, "none"), pkgdown_file = file,
    path_presentations = dir
  )
  menu <- yaml::read_yaml(file)$navbar$components$presentations$menu
  expect_equal(
    vapply(menu, function(x) x$text, ""),
    c("Package", "Data", "---------", "Others", "Copil", "Point", "Atelier")
  )
})

test_that("menu_category classifies by folder name", {
  expect_equal(
    menu_category(c("01_a", "20261020_b", "c", "1_d", "02-former")),
    c("package", "others", "others", "package", "package")
  )
  expect_equal(
    menu_category(c("01_a", "b"), list("Others", NULL)),
    c("others", "others")
  )
})

test_that("menu_lang reads the language suffix, former naming too", {
  expect_equal(
    menu_lang(c("01_a_fr", "b_en", "c-fr", "d")),
    c("fr", "en", "fr", "")
  )
})

test_that("build_site gives path_site to pkgdown, dev folder included", {
  dir <- local_book_env()
  suppressMessages(create_book("a_fr", path_reports = dir))
  withr::local_dir(dir)
  calls <- list()
  built <- NULL
  local_mocked_bindings(
    run_renders = function(renders, workers) {
      calls <<- c(calls, lapply(renders, render_output_dir))
    },
    .package = "kquarto.r"
  )
  local_mocked_bindings(
    pkgdown_init_site = function(...) NULL,
    pkgdown_build_site = function(...) built <<- list(...),
    # a development version: pkgdown writes in <destination>/dev
    pkgdown_dst_path = function(override) {
      file.path(override$destination, "dev")
    }
  )
  build_site(path_reports = ".", path_site = "site")
  expect_match(calls[[1]], "site[/\\\\]dev[/\\\\]reports[/\\\\]a_fr$")
  expect_equal(built$override, list(destination = "site"))

  # an override given by the caller is kept
  build_site(
    path_reports = ".", path_site = "site",
    override = list(destination = "other", url = "u")
  )
  expect_equal(built$override, list(destination = "other", url = "u"))
})

test_that("build_site and update_pkgdown_yml accept the former names", {
  dir <- local_book_env()
  suppressMessages(create_book("a_fr", path_reports = dir))
  withr::local_dir(dir)
  calls <- list()
  built <- NULL
  local_mocked_bindings(
    run_renders = function(renders, workers) {
      calls <<- c(calls, lapply(renders, render_output_dir))
    },
    .package = "kquarto.r"
  )
  local_mocked_bindings(
    pkgdown_init_site = function(...) NULL,
    pkgdown_build_site = function(...) built <<- list(...)
  )
  expect_warning(
    expect_warning(
      build_site(path = ".", dest = "public"),
      "`path` is deprecated, use `path_reports`"
    ),
    "`dest` is deprecated, use `path_site`"
  )
  # with `dest`, as before: no override, the books in `dest`
  expect_match(calls[[1]], "public[/\\\\]reports[/\\\\]a_fr$")
  expect_null(built$override)

  expect_warning(
    update_pkgdown_yml(path = ".", pkgdown_file = "p.yml"),
    "`path` is deprecated"
  )
  expect_true(file.exists("p.yml"))
})
