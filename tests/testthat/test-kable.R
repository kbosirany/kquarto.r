test_that("kable() makes a scrollable table in HTML output", {
  skip_if_not_installed("kableExtra")
  tab <- kable(head(iris), is_html_output = TRUE, title = "Iris")

  expect_s3_class(tab, "knitr_kable")
  expect_match(as.character(tab), "overflow", fixed = TRUE)
  expect_match(as.character(tab), "Iris", fixed = TRUE)
})

test_that("kable() sets the height of the scroll box", {
  skip_if_not_installed("kableExtra")
  tab <- kable(head(iris), is_html_output = TRUE, height = "123px")

  expect_match(as.character(tab), "123px", fixed = TRUE)
})

test_that("kable() writes the whole table as Markdown outside HTML", {
  tab <- kable(iris, is_html_output = FALSE, title = "Iris")

  expect_s3_class(tab, "knitr_kable")
  expect_match(paste(tab, collapse = "\n"), "|setosa", fixed = TRUE)
  expect_match(paste(tab, collapse = "\n"), "|virginica", fixed = TRUE)
  expect_match(paste(tab, collapse = "\n"), "Iris", fixed = TRUE)
  expect_equal(sum(grepl("^\\|", tab)), nrow(iris) + 2)
})

test_that("kable() makes a booktabs table in LaTeX output", {
  local_mocked_bindings(is_latex_output = function() TRUE, .package = "knitr")
  tab <- kable(iris, is_html_output = FALSE, title = "Iris")

  expect_match(as.character(tab), "toprule", fixed = TRUE)
  expect_match(paste(tab, collapse = ""), "virginica", fixed = TRUE)
})

test_that("kable() asks for kableExtra in HTML output", {
  local_mocked_bindings(has_kableextra = function() FALSE)
  expect_error(kable(head(iris), is_html_output = TRUE), "kableExtra")
})
