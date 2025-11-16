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

# Install base R packages
RUN R -e "install.packages('remotes', repos='https://cloud.r-project.org/')" && \
    R -e "install.packages(c('DBI', 'dplyr', 'readr', 'stringr', 'lubridate', 'data.table', 'httr'), repos='https://cloud.r-project.org/')"

# Install OHDSI packages and verify each one
RUN R -e "install.packages('SqlRender', repos='https://cloud.r-project.org/')" && \
    R -e "library(SqlRender); cat('SqlRender OK\n')"

RUN R -e "install.packages('DatabaseConnector', repos='https://cloud.r-project.org/')" && \
    R -e "library(DatabaseConnector); cat('DatabaseConnector OK\n')"

RUN R -e "remotes::install_github('OHDSI/CommonDataModel', upgrade='never')" && \
    R -e "library(CommonDataModel); cat('CommonDataModel OK\n')"

# Now install ETL-Synthea
RUN cd /tmp && \
    wget -O etl-synthea.tar.gz https://github.com/OHDSI/ETL-Synthea/tarball/master && \
    tar -xzf etl-synthea.tar.gz && \
    mv OHDSI-ETL-Synthea-* ETL-Synthea && \
    R CMD INSTALL /tmp/ETL-Synthea && \
    rm -rf /tmp/ETL-Synthea /tmp/etl-synthea.tar.gz

# Final verification
RUN R -e "library(ETLSyntheaBuilder); cat('SUCCESS: ETLSyntheaBuilder installed!\n')"

WORKDIR /app
CMD ["R"]