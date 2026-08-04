# Reference environment for the Code Ocean capsule.
#
# Code Ocean's own workflow is to pick a base image in the capsule's Environment
# tab and add packages there; it then maintains this file itself. Keep this copy
# as the record of what the analysis actually needs, and reconcile it against
# whatever the Environment tab produces -- log_sessionInfo.txt in the results is
# the ground truth for any published run.
#
# The capsule does not use the FROM line below. Its base image is pinned in
# .codeocean/environment.json, currently the platform's R 4.5.1 / RStudio image
# on Ubuntu 22.04 (jammy). This file stays on rocker/r-ver so it remains buildable
# outside Code Ocean; the two differ in R version only, which is immaterial here
# for the reasons given below.
#
# rocker/r-ver pins CRAN to a snapshot matching the R release date and installs
# Linux binaries from Posit Package Manager, so `install.packages` here is both
# fast and version-stable.
#
# R version: 4.6.1 is what produced the submitted figures, but it is not a
# requirement. The strictest dependency in the stack is R (>= 4.1.0), from dplyr,
# sf, tidyr, and ggrepel; nothing here needs 4.6. The analysis code uses no
# version-gated syntax -- no native pipe, no lambda shorthand, no version checks.
# Any R >= 4.1 will run it, so pick whatever base image the platform offers.
#
# Package versions used to produce the submitted figures:
#   arrow 24.0.0        data.table 1.18.4   dplyr 1.2.1
#   ggplot2 4.0.3       lubridate 1.9.5     patchwork 1.3.2
#   rnaturalearth 1.2.0 rnaturalearthdata 1.0.0.9000 (CRAN 1.0.0 is equivalent
#                       for the medium-scale basemap this analysis uses)
#   scales 1.4.0        sf 1.1.1            tidyr 1.3.2
#
# These matter more than the R version. rocker/r-ver pins CRAN to a snapshot
# matching its R release date, so an older base image silently resolves to older
# packages -- an R 4.5.1 image yields ggplot2 3.5.x, a major version behind the
# 4.0.3 that rendered the figures. Pin the versions above rather than accepting
# the snapshot default; all of them install on R >= 4.1.

FROM rocker/r-ver:4.6.1

# Geospatial and I/O system libraries: sf needs GDAL/PROJ/GEOS/udunits,
# arrow and the http-facing packages need ssl/curl/xml2.
RUN apt-get update && apt-get install -y --no-install-recommends \
        libgdal-dev \
        libproj-dev \
        libgeos-dev \
        libudunits2-dev \
        libsqlite3-dev \
        libssl-dev \
        libcurl4-openssl-dev \
        libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Three of these are never named in a library() call, so they are invisible to a
# scan of the source and easy to omit: hexbin backs geom_hex in Figure 1, maps
# supplies the outlines behind ggplot2::map_data("state") in Figure 2, and
# ggrepel::geom_text_repel labels that same panel. Omitting any of them fails at
# draw time, not load time -- the run dies partway through with figures already
# written, which reads like a data problem rather than a missing package.
RUN Rscript -e 'install.packages(c("arrow", "data.table", "dplyr", "ggplot2", "ggrepel", "hexbin", "lubridate", "maps", "patchwork", "rnaturalearth", "rnaturalearthdata", "scales", "sf", "tidyr"))'

# make_figures.R calls ne_countries(scale = "medium"), whose basemap ships inside
# the rnaturalearthdata package -- so the run needs no network access. Do not
# switch that call to scale = "large": that basemap lives in rnaturalearthhires,
# which is not on CRAN and would have to be fetched at runtime.
RUN Rscript -e 'stopifnot(nrow(rnaturalearth::ne_countries(scale = "medium", returnclass = "sf")) > 0)'
