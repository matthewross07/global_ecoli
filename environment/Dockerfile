# Environment for the Code Ocean capsule.
#
# This file IS the capsule's build definition, not a record of one. Committing a
# hand-written Dockerfile here puts Code Ocean into custom-environment mode and
# disables the Environment Editor GUI, so everything the analysis needs -- system
# libraries and R packages alike -- has to be declared below. Nothing installed
# by hand in a Cloud Workstation survives into a Reproducible Run.
#
# The base image below is Code Ocean's own. Keeping their image (rather than
# rocker/r-ver) preserves the platform integration: RStudio Server, the expected
# user and paths, and a working Cloud Workstation. To build this outside Code
# Ocean, swap the FROM line for `rocker/r-ver:4.5.1` -- everything below is
# base-image agnostic.
#
# The capsule records the same image in .codeocean/environment.json, which is
# deliberately NOT tracked in git: Code Ocean owns that path and never checks it
# out, so a tracked copy shows up forever as a deleted file and blocks pushes.
# If the two ever disagree, .codeocean/environment.json is what actually builds
# and this FROM line needs updating to match.
#
# R version: 4.6.1 produced the submitted figures, but it is not a requirement.
# The strictest dependency in the stack is R (>= 4.1.0), from dplyr, sf, tidyr,
# and ggrepel. The analysis code uses no version-gated syntax -- no native pipe,
# no lambda shorthand, no version checks -- so R 4.5.1 runs it unchanged.
#
# Package versions used to produce the submitted figures:
#   arrow 24.0.0        data.table 1.18.4   dplyr 1.2.1
#   ggplot2 4.0.3       lubridate 1.9.5     patchwork 1.3.2
#   rnaturalearth 1.2.0 rnaturalearthdata 1.0.0.9000 (CRAN 1.0.0 is equivalent
#                       for the medium-scale basemap this analysis uses)
#   scales 1.4.0        sf 1.1.1            tidyr 1.3.2
#
# These matter more than the R version, which is why the repo is pinned to a
# dated Posit Package Manager snapshot below. Left to its own devices this base
# image resolves to ggplot2 3.5.2 and dplyr 1.1.4 -- ggplot2 being a full major
# version behind what rendered the figures. The snapshot also serves prebuilt
# jammy binaries, which matters enormously for sf, terra, and arrow: from source
# they are a long and failure-prone compile.

FROM registry.codeocean.com/codeocean/r-studio:r-4.5.1-1.2204.0-rstudio-server-2025.05.1-513-ubuntu22.04

# Geospatial and I/O system libraries. sf and terra both compile against
# GDAL/PROJ/GEOS, and terra is not optional -- rnaturalearth imports it. Without
# libgdal-dev the build fails at `configure: error: gdal-config not found`.
# units (via sf) needs udunits2; arrow and the http-facing packages need
# ssl/curl/xml2.
RUN apt-get update && apt-get install -y --no-install-recommends \
        libgdal-dev \
        libproj-dev \
        libgeos-dev \
        libudunits2-dev \
        libsqlite3-dev \
        libssl-dev \
        libcurl4-openssl-dev \
        libxml2-dev \
        libicu-dev \
    && rm -rf /var/lib/apt/lists/*

# This list was derived, not guessed: `ldd` against the compiled .so files of a
# known-working install shows sf and terra linking libgdal, libgeos, libproj,
# libsqlite3, libssl, libcurl and libxml2; units linking libudunits2; and arrow,
# s2 and stringi linking libicu. Anything beyond these (libz, libbz2, liblz4,
# libzstd, libsnappy) is either already in the base image or vendored by the
# arrow binary.

# Three of these are never named in a library() call, so they are invisible to a
# scan of the source and easy to omit: hexbin backs geom_hex in Figure 1, maps
# supplies the outlines behind ggplot2::map_data("state") in Figure 2, and
# ggrepel::geom_text_repel labels that same panel. Omitting any of them fails at
# draw time, not load time -- the run dies partway through with figures already
# written, which reads like a data problem rather than a missing package.
#
# The dated snapshot is deliberate: `latest` would make this environment drift.
RUN Rscript -e 'options(repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/jammy/2026-08-01")); \
      install.packages(c("arrow", "data.table", "dplyr", "ggplot2", "ggrepel", \
                         "hexbin", "lubridate", "maps", "patchwork", \
                         "rnaturalearth", "rnaturalearthdata", "scales", "sf", \
                         "tidyr"))'

# Fail the build, not the run, if anything above did not land. Every one of these
# is loaded by the analysis, and a missing package that only surfaces mid-figure
# costs far more to diagnose than a failed build does.
RUN Rscript -e 'pk <- c("arrow","data.table","dplyr","ggplot2","ggrepel","hexbin", \
                        "lubridate","maps","patchwork","rnaturalearth", \
                        "rnaturalearthdata","scales","sf","tidyr"); \
      miss <- pk[!vapply(pk, requireNamespace, logical(1), quietly = TRUE)]; \
      if (length(miss)) stop("missing packages: ", paste(miss, collapse = ", ")); \
      print(installed.packages()[pk, "Version"])'

# make_figures.R calls ne_countries(scale = "medium"), whose basemap ships inside
# the rnaturalearthdata package -- so the run needs no network access. Do not
# switch that call to scale = "large": that basemap lives in rnaturalearthhires,
# which is not on CRAN and would have to be fetched at runtime.
RUN Rscript -e 'stopifnot(nrow(rnaturalearth::ne_countries(scale = "medium", returnclass = "sf")) > 0)'
