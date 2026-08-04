# Reference environment for the Code Ocean capsule.
#
# Code Ocean's own workflow is to pick a base image in the capsule's Environment
# tab and add packages there; it then maintains this file itself. Keep this copy
# as the record of what the analysis actually needs, and reconcile it against
# whatever the Environment tab produces -- log_sessionInfo.txt in the results is
# the ground truth for any published run.
#
# rocker/r-ver pins CRAN to a snapshot matching the R release date and installs
# Linux binaries from Posit Package Manager, so `install.packages` here is both
# fast and version-stable.
#
# Package versions used to produce the submitted figures:
#   arrow 24.0.0        data.table 1.18.4   dplyr 1.2.1
#   ggplot2 4.0.3       lubridate 1.9.5     patchwork 1.3.2
#   rnaturalearth 1.2.0 rnaturalearthdata 1.0.0.9000 (CRAN 1.0.0 is equivalent
#                       for the medium-scale basemap this analysis uses)
#   scales 1.4.0        sf 1.1.1            tidyr 1.3.2

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

# ggrepel and maps are Figure 2 only: ggrepel::geom_text_repel labels the
# Wisconsin sites, and ggplot2::map_data("state") loads its outlines from maps.
RUN Rscript -e 'install.packages(c("arrow", "data.table", "dplyr", "ggplot2", "ggrepel", "lubridate", "maps", "patchwork", "rnaturalearth", "rnaturalearthdata", "scales", "sf", "tidyr"))'

# make_figures.R calls ne_countries(scale = "medium"), whose basemap ships inside
# the rnaturalearthdata package -- so the run needs no network access. Do not
# switch that call to scale = "large": that basemap lives in rnaturalearthhires,
# which is not on CRAN and would have to be fetched at runtime.
RUN Rscript -e 'stopifnot(nrow(rnaturalearth::ne_countries(scale = "medium", returnclass = "sf")) > 0)'
