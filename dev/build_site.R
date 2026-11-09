# Build the pkgdown site, with the books and presentations of `reports/` and
# `presentations/`: this is kquarto.r::build_site() (the package of the
# branch is installed by the CI before).
#
# Run from the package root:
#   Rscript dev/build_site.R
# Called by the GitLab CI job of the site, which sets:
# - KPKG_DEST: folder of the site (default `docs`);
# - KPKG_OUTPUT_FORMAT: formats rendered in addition to the HTML, separated
#   by commas, e.g. "typst,beamer" (default: none);
# - PKGDOWN_DEV_MODE: "release" or "devel" (the site of the dev branch is
#   written in `<destination>/dev`), read by pkgdown;
# - CI_PAGES_URL: URL of the site (GitLab).

output_format <- strsplit(Sys.getenv("KPKG_OUTPUT_FORMAT"), ",")[[1]]
override <- list()
if (nzchar(Sys.getenv("CI_PAGES_URL"))) {
  override$url <- Sys.getenv("CI_PAGES_URL")
}

kquarto.r::build_site(
  path_site = Sys.getenv("KPKG_DEST", "docs"),
  output_format = if (length(output_format)) output_format,
  new_process = FALSE,
  override = override
)
