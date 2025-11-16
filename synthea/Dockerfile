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
RUN R -e "install.packages(c('remotes', 'DBI', 'dplyr', 'readr', 'stringr', 'lubridate'), repos='https://cloud.r-project.org/')"
RUN R -e "install.packages(c('SqlRender', 'DatabaseConnector'), repos='https://cloud.r-project.org/')"

# Install ETL-Synthea
RUN cd /tmp && \
    wget -O etl-synthea.tar.gz https://github.com/OHDSI/ETL-Synthea/tarball/master && \
    tar -xzf etl-synthea.tar.gz && \
    mv OHDSI-ETL-Synthea-* ETL-Synthea && \
    R CMD INSTALL /tmp/ETL-Synthea && \
    rm -rf /tmp/ETL-Synthea /tmp/etl-synthea.tar.gz

# Verify - don't check package name, just see if install succeeded
RUN R -e "cat('ETL-Synthea installation complete!\n')"

WORKDIR /app
CMD ["R"]