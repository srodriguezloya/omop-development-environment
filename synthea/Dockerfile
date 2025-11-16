# Modern ETL-Synthea Dockerfile
FROM rocker/r-ver:4.4.1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libpq-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "install.packages(c('remotes', 'DBI', 'dplyr', 'readr'), repos='https://cloud.r-project.org/')"
RUN R -e "install.packages(c('SqlRender', 'DatabaseConnector'), repos='https://cloud.r-project.org/')"

# Install ETL-Synthea - Note: correct repo name is ETL-Synthea (with hyphen)
RUN cd /tmp && \
    wget -O etl-synthea.tar.gz https://github.com/OHDSI/ETL-Synthea/tarball/master && \
    tar -xzf etl-synthea.tar.gz && \
    mv OHDSI-ETL-Synthea-* ETL-Synthea && \
    R -e "remotes::install_local('/tmp/ETL-Synthea', upgrade='never', dependencies=FALSE)" && \
    rm -rf /tmp/ETL-Synthea /tmp/etl-synthea.tar.gz

# Verify
RUN R -e "library(ETLSyntheaBuilder); cat('ETLSyntheaBuilder installed!\n')"

WORKDIR /app
CMD ["R"]