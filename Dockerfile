# Image of the CI and of the dev container: R, Quarto, pandoc, Chrome (for
# the screenshots of the widgets in the PDF) and pak. The R packages of the
# project and their system libraries are not in the image: pak installs them
# (in a CI, keep their library in the cache of the runner).
#
# Build, with the version of R (latest, devel, 4.4...):
#   docker build --build-arg R_VERSION=latest -t kquarto.r:latest .
ARG R_VERSION=latest
FROM rocker/r-ver:${R_VERSION}

ENV DEBIAN_FRONTEND=noninteractive \
    PKG_SYSREQS=true \
    NOT_CRAN=true

RUN apt-get update -qq \
 && apt-get install -y -qq --no-install-recommends \
      pandoc qpdf git curl ca-certificates \
      libcurl4-openssl-dev libssl-dev libxml2-dev pkg-config \
 && rm -rf /var/lib/apt/lists/*

# Quarto CLI (script of the rocker images), with its Typst
RUN /rocker_scripts/install_quarto.sh

# Chrome, for chromote / webshot2. Chromium is a snap on Ubuntu, and pak
# adds a PPA (Launchpad) when no browser is found: with Chrome here, it
# does not. The Google package exists for amd64 only.
RUN curl -fsSL -o /tmp/chrome.deb \
      https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
 && apt-get update -qq \
 && apt-get install -y -qq --no-install-recommends /tmp/chrome.deb \
 && rm -rf /tmp/chrome.deb /var/lib/apt/lists/*

# pak from the binaries of r-lib: R-devel has no binaries on CRAN, and
# building pak from the sources takes about 3 minutes
RUN Rscript -e ' \
  pak_repo <- sprintf( \
    "https://r-lib.github.io/p/pak/stable/%s/%s/%s", \
    .Platform$pkgType, R.Version()$os, R.Version()$arch); \
  install.packages("pak", repos = pak_repo); \
  if (!requireNamespace("pak", quietly = TRUE)) install.packages("pak")'

# The system libraries of the R packages are installed by pak, with the
# packages (PKG_SYSREQS): pak::local_system_requirements() does not know the
# Ubuntu of the latest image yet.

WORKDIR /workspace
