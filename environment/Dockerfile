# hash:sha256:3a9db0b7bc1ac0fe8b77811daf9d62e20e69403f156e77c9f8adf80faeba2b1e
FROM registry.codeocean.com/codeocean/r-studio:r-4.5.1-1.2204.0-rstudio-server-2025.05.1-513-ubuntu22.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libcurl4-openssl-dev \
        libgeos-dev \
        libicu-dev \
        libproj-dev \
        libsqlite3-dev \
        libssl-dev \
        libudunits2-dev \
        libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

RUN Rscript -e 'remotes::install_version("arrow", "24.0.0")' \
    && Rscript -e 'remotes::install_version("data.table", "1.18.4")' \
    && Rscript -e 'remotes::install_version("dplyr", "1.2.1")' \
    && Rscript -e 'remotes::install_version("ggplot2", "4.0.3")' \
    && Rscript -e 'remotes::install_version("ggrepel", "0.9.8")' \
    && Rscript -e 'remotes::install_version("hexbin", "1.28.5")' \
    && Rscript -e 'remotes::install_version("lubridate", "1.9.5")' \
    && Rscript -e 'remotes::install_version("maps", "3.4.3")' \
    && Rscript -e 'remotes::install_version("patchwork", "1.3.2")' \
    && Rscript -e 'remotes::install_version("rnaturalearth", "1.2.0")' \
    && Rscript -e 'remotes::install_version("rnaturalearthdata", "1.0.0")' \
    && Rscript -e 'remotes::install_version("scales", "1.4.0")' \
    && Rscript -e 'remotes::install_version("sf", "1.1.1")' \
    && Rscript -e 'remotes::install_version("tidyr", "1.3.2")'
