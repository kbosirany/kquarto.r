test_that("kable() makes a scrollable table in HTML output", {
  tab <- kable(head(iris), is_html_output = TRUE, title = "Iris")

  expect_s3_class(tab, "knitr_kable")
  expect_match(as.character(tab), "overflow", fixed = TRUE)
  expect_match(as.character(tab), "Iris", fixed = TRUE)
})

test_that("kable() sets the height of the scroll box", {
  tab <- kable(head(iris), is_html_output = TRUE, height = "123px")

  expect_match(as.character(tab), "123px", fixed = TRUE)
})

test_that("kable() makes a booktabs table of the first rows in LaTeX", {
  tab <- kable(iris, is_html_output = FALSE, title = "Iris")

  expect_match(as.character(tab), "toprule", fixed = TRUE)
  expect_equal(sum(grepl("setosa", as.character(tab))), 1)
  expect_false(grepl("virginica", paste(tab, collapse = "")))
})
