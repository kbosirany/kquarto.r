local_book_env <- function(env = parent.frame()) {
  dir <- withr::local_tempdir(.local_envir = env)
  withr::local_options(
    list(kquarto.r.template_dir = file.path(dir, ".templates")),
    .local_envir = env
  )
  dir
}
