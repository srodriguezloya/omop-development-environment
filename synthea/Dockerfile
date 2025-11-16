FROM rocker/r-ver:4.4.1

# Install system dependencies for OHDSI R packages
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

# Install R package dependencies
RUN R -e "install.packages(c('remotes', 'DBI', 'dplyr', 'readr'), repos='https://cloud.r-project.org/')"

# Install OHDSI packages (SqlRender and DatabaseConnector from CRAN)
RUN R -e "install.packages(c('SqlRender', 'DatabaseConnector'), repos='https://cloud.r-project.org/')"

# Install ETL-Synthea by downloading tarball with wget
RUN cd /tmp && \
    wget -O etl-synthea.tar.gz https://github.com/OHDSI/ETLSyntheaBuilder/tarball/master && \
    tar -xzf etl-synthea.tar.gz && \
    mv OHDSI-ETLSyntheaBuilder-* ETLSyntheaBuilder && \
    R -e "remotes::install_local('/tmp/ETLSyntheaBuilder', upgrade='never', dependencies=FALSE)" && \
    rm -rf /tmp/ETLSyntheaBuilder /tmp/etl-synthea.tar.gz

# Verify installation
RUN R -e "library(ETLSyntheaBuilder); cat('ETLSyntheaBuilder version:', as.character(packageVersion('ETLSyntheaBuilder')), '\n')"

# Set working directory
WORKDIR /app

# Default command
CMD ["R"]