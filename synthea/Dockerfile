# Modern ETL-Synthea Dockerfile
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
    git \
    && rm -rf /var/lib/apt/lists/*

# Install R package dependencies
# Install in order of dependencies to avoid conflicts
RUN R -e "install.packages(c('remotes', 'DBI', 'dplyr', 'readr'), repos='https://cloud.r-project.org/')"

# Install OHDSI packages from CRAN/GitHub
# SqlRender and DatabaseConnector are on CRAN, use those versions (more stable)
RUN R -e "install.packages(c('SqlRender', 'DatabaseConnector'), repos='https://cloud.r-project.org/')"

# Install ETL-Synthea from GitHub (latest stable)
# Use upgrade='never' to avoid reinstalling dependencies
RUN R -e "remotes::install_github('OHDSI/ETLSyntheaBuilder', upgrade='never')"

# Verify installation
RUN R -e "library(ETLSyntheaBuilder); cat('ETLSyntheaBuilder version:', as.character(packageVersion('ETLSyntheaBuilder')), '\n')"

# Set working directory
WORKDIR /etl

# Default command
CMD ["R"]