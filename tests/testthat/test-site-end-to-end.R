# Real Quarto renders (no mock of run_renders): the files of the site.
skip_if_no_site_tools <- function() {
  skip_on_cran()
  skip_if(is.null(quarto::quarto_path()), "Quarto CLI not installed")
  version <- system2(quarto::quarto_path(), "--version", stdout = TRUE)
  skip_if(
    package_version(trimws(version[[1]])) < "1.4",
    "Typst books need Quarto >= 1.4"
  )
}

local_site_project <- function(env = parent.frame()) {
  dir <- local_book_env(env)
  withr::local_dir(dir, .local_envir = env)
  dir.create("reports")
  dir.create("presentations")
  suppressMessages(create_book(
    "a_fr", author = "A", formats = c("html", "typst"),
    chapters = "Introduction"
  ))
  suppressMessages(create_presentation("point"))
  # pkgdown needs a package: the site folder is the destination
  local_mocked_bindings(
    pkgdown_dst_path = function(override) override$destination,
    pkgdown_init_site = function(...) NULL,
    pkgdown_build_site = function(...) "built",
    .env = env
  )
  dir
}

test_that("render_site_item writes the HTML, then adds the other formats", {
  skip_if_no_site_tools()
  local_site_project()

  render_site_item("reports/a_fr", output_format = "typst")
  expect_true(file.exists("public/reports/a_fr/index.html"))
  # the other format did not remove the HTML (Quarto empties an output
  # folder inside the book folder when it renders another format in it)
  expect_length(list.files("public/reports/a_fr", pattern = "[.]pdf$"), 1)

  render_site_item("presentations/point")
  expect_true(file.exists("public/presentations/point/index.html"))
})

test_that("build_site checks the items rendered by other jobs", {
  skip_if_no_site_tools()
  local_site_project()
  args <- list(
    path_site = "public", render_reports = FALSE,
    render_presentations = FALSE, check_rendered = TRUE
  )
  expect_error(do.call(build_site, args), "reports/a_fr, presentations/point")

  render_site_item("reports/a_fr")
  render_site_item("presentations/point")
  expect_equal(do.call(build_site, args), "built")

  unlink("public/reports/a_fr/index.html")
  expect_error(do.call(build_site, args), "reports/a_fr")
})
