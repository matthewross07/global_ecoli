# hash:sha256:255cfcb5eb2a8641cffc70dd450ca97d4efae7e24d0a9e859fa68a91c8f66dd0
FROM registry.codeocean.com/codeocean/r-studio:r-4.5.1-1.2204.0-rstudio-server-2025.05.1-513-ubuntu22.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libcurl4-openssl-dev=7.81.0-1ubuntu1.25 \
        libgdal-dev \
        libgeos-dev=3.10.2-1 \
        libicu-dev=70.1-2 \
        libproj-dev=8.2.1-1 \
        libsqlite3-dev=3.37.2-2ubuntu0.7 \
        libssl-dev=3.0.2-0ubuntu1.26 \
        libudunits2-dev=2.2.28-3 \
        libxml2-dev=2.9.13+dfsg-1ubuntu0.12 \
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

COPY postInstall /
RUN /postInstall
