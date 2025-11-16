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
RUN R -e "install.packages('remotes', repos='https://cloud.r-project.org/')"
RUN R -e "install.packages(c('DBI', 'dplyr', 'readr'), repos='https://cloud.r-project.org/')"

# Install SqlRender with error output visible
RUN R -e " \
    options(warn=2); \
    install.packages('SqlRender', repos='https://cloud.r-project.org/', dependencies=TRUE); \
    if (!require('SqlRender', quietly=TRUE)) { \
        cat('FAILED TO INSTALL SqlRender\n'); \
        quit(status=1); \
    } else { \
        cat('SqlRender installed successfully\n'); \
    } \
"

# Install DatabaseConnector
RUN R -e " \
    install.packages('DatabaseConnector', repos='https://cloud.r-project.org/', dependencies=TRUE); \
    library(DatabaseConnector); \
    cat('DatabaseConnector OK\n'); \
"

# Install CommonDataModel and ETLSyntheaBuilder together from GitHub
RUN R -e " \
    remotes::install_github('OHDSI/CommonDataModel', upgrade='never'); \
    remotes::install_github('OHDSI/ETL-Synthea', upgrade='never'); \
"

# Verify
RUN R -e "library(ETLSyntheaBuilder); cat('SUCCESS!\n')"

WORKDIR /app
CMD ["R"]