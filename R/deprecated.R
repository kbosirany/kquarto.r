# The value of a renamed argument: `new`, or `old` (the value of the former
# name) with a deprecation warning when it is given.
renamed_arg <- function(new, old, name_new, name_old) {
  if (is.null(old)) {
    return(new)
  }
  warning(
    "`", name_old, "` is deprecated, use `", name_new, "` instead.",
    call. = FALSE
  )
  old
}
