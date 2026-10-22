local_book_env <- function(env = parent.frame()) {
  dir <- withr::local_tempdir(.local_envir = env)
  withr::local_options(
    list(kquarto.r.template_dir = file.path(dir, ".templates")),
    .local_envir = env
  )
  dir
}

read_config <- function(dir, book) {
  yaml::read_yaml(file.path(dir, book, "_quarto.yml"))
}

# The output folder given to Quarto by a book render (see book_renders()).
render_output_dir <- function(render) {
  args <- render$args$quarto_args
  args[[match("--output-dir", args) + 1]]
}

# Writes the HTML of the slides among `renders`, as Quarto would.
mock_render_slides <- function(renders) {
  for (render in renders) {
    if (grepl("[.]qmd$", render$args$input)) {
      writeLines("<html></html>", sub("[.]qmd$", ".html", render$args$input))
    }
  }
}
