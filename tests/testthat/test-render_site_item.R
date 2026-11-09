local_site_env <- function(env = parent.frame()) {
  dir <- local_book_env(env)
  dir.create(file.path(dir, "reports"))
  dir.create(file.path(dir, "presentations"))
  withr::local_dir(dir, .local_envir = env)
  suppressMessages(create_book(
    "a_fr", author = "A", formats = c("html", "typst")
  ))
  suppressMessages(create_presentation(
    "point", formats = c("revealjs", "beamer")
  ))
  local_mocked_bindings(
    pkgdown_dst_path = function(override) {
      file.path(override$destination, "dev")
    },
    .env = env
  )
  dir
}

test_that("render_site_item renders a book in the site, HTML first", {
  local_site_env()
  passes <- list()
  local_mocked_bindings(
    run_renders = function(renders, workers = 1L) {
      for (render in renders) {
        out <- render_output_dir(render)
        passes[[length(passes) + 1]] <<- render$args$output_format
        file.create(file.path(
          out, if (identical(render$args$output_format, "typst")) {
            "book.pdf"
          } else {
            "index.html"
          }
        ))
      }
    },
    .package = "kquarto.r"
  )
  target <- render_site_item("reports/a_fr", output_format = "typst")
  expect_match(target, "public[/\\\\]dev[/\\\\]reports[/\\\\]a_fr$")
  expect_equal(unlist(passes), c("html", "typst"))
  expect_true(file.exists("public/dev/reports/a_fr/index.html"))
  expect_true(file.exists("public/dev/reports/a_fr/book.pdf"))
})

test_that("render_site_item renders a presentation in the site", {
  local_site_env()
  formats <- list()
  local_mocked_bindings(
    run_renders = function(renders, workers = 1L) {
      formats[[length(formats) + 1]] <<- renders[[1]]$args$output_format
      mock_render_slides(renders)
    },
    .package = "kquarto.r"
  )
  render_site_item("presentations/point/")
  expect_equal(unlist(formats), "revealjs")
  expect_true(file.exists("public/dev/presentations/point/index.html"))
})

test_that("render_site_item skips an absent item and rejects a wrong one", {
  local_site_env()
  local_mocked_bindings(
    run_renders = function(...) stop("nothing to render"),
    .package = "kquarto.r"
  )
  expect_message(
    expect_null(render_site_item("reports/other_fr")), "nothing to render"
  )
  expect_error(render_site_item("elsewhere/a_fr"), "Not in `reports`")
  expect_error(render_site_item(c("reports/a", "reports/b")), "one book")
})

test_that("build_site(check_rendered = TRUE) needs the rendered items", {
  local_site_env()
  local_mocked_bindings(
    pkgdown_init_site = function(...) NULL,
    pkgdown_build_site = function(...) "built",
    pkgdown_dst_path = function(override) override$destination
  )
  args <- list(
    render_reports = FALSE, render_presentations = FALSE,
    check_rendered = TRUE
  )
  expect_error(
    do.call(build_site, args), "reports/a_fr, presentations/point"
  )
  dir.create("public/reports/a_fr", recursive = TRUE)
  file.create("public/reports/a_fr/index.html")
  expect_error(do.call(build_site, args), "presentations/point")
  dir.create("public/presentations/point", recursive = TRUE)
  file.create("public/presentations/point/index.html")
  expect_equal(do.call(build_site, args), "built")
})
