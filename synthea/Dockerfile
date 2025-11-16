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

# Install R dependencies step by step
RUN R -e "install.packages('remotes', repos='https://cloud.r-project.org/')"
RUN R -e "install.packages(c('DBI', 'dplyr', 'readr', 'stringr', 'lubridate', 'data.table'), repos='https://cloud.r-project.org/')"
RUN R -e "install.packages('httr', repos='https://cloud.r-project.org/', dependencies=TRUE)"
RUN R -e "install.packages(c('SqlRender', 'DatabaseConnector'), repos='https://cloud.r-project.org/')"

# Install CommonDataModel from GitHub
RUN R -e "remotes::install_github('OHDSI/CommonDataModel', upgrade='never', dependencies=FALSE)"

# Install ETL-Synthea
RUN cd /tmp && \
    wget -O etl-synthea.tar.gz https://github.com/OHDSI/ETL-Synthea/tarball/master && \
    tar -xzf etl-synthea.tar.gz && \
    mv OHDSI-ETL-Synthea-* ETL-Synthea && \
    R CMD INSTALL /tmp/ETL-Synthea && \
    rm -rf /tmp/ETL-Synthea /tmp/etl-synthea.tar.gz

# Verify
RUN R -e "library(ETLSyntheaBuilder); cat('ETLSyntheaBuilder installed successfully!\n')"

WORKDIR /app
CMD ["R"]