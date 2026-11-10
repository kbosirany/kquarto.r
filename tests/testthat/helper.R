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

# Quarto compiles the PDF with LuaLaTeX by default. Its fonts need
# luaotfload and the French books need babel-french, which some
# distributions ship apart from the `lualatex` binary (Debian: texlive-luatex
# and texlive-lang-french). TinyTeX installs them when needed.
skip_if_no_lualatex <- function() {
  skip_if(!nzchar(Sys.which("lualatex")), "LuaLaTeX not installed")
  kpsewhich <- Sys.which("kpsewhich")
  has_file <- function(file) {
    nzchar(kpsewhich) && length(suppressWarnings(
      system2(kpsewhich, file, stdout = TRUE, stderr = FALSE)
    )) > 0
  }
  skip_if(!has_file("luaotfload.sty"), "luaotfload not installed (fonts)")
  skip_if(!has_file("french.ldf"), "babel-french not installed")
}
