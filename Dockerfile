FROM rocker/r-ver:4.4.0

# System libraries needed by simulatr's Imports/Suggests (curl/xml2/openssl
# for remotes; libgit2 for devtools-equivalents; pandoc for vignettes).
RUN apt-get update && apt-get install -y --no-install-recommends \
        libcurl4-openssl-dev \
        libssl-dev \
        libxml2-dev \
        libgit2-dev \
        libfontconfig1-dev \
        libfreetype6-dev \
        libharfbuzz-dev \
        libfribidi-dev \
        libpng-dev \
        libtiff5-dev \
        libjpeg-dev \
        pandoc \
        git \
    && rm -rf /var/lib/apt/lists/*

RUN R -e "install.packages(c('remotes', 'pak'), repos = 'https://packagemanager.posit.co/cran/__linux__/jammy/latest')"

# Install simulatr from the current source tree (see .dockerignore for
# what is excluded from the build context). On release tags the docker
# workflow rebuilds and pushes :<version> + :latest to GHCR.
COPY . /opt/simulatr
RUN R -e "remotes::install_local('/opt/simulatr', dependencies = TRUE, upgrade = 'never')"

CMD ["R"]
