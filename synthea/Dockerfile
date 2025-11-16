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
RUN R -e "install.packages(c('remotes', 'DBI', 'dplyr', 'readr'), repos='https://cloud.r-project.org/')"

# Install OHDSI packages (SqlRender and DatabaseConnector from CRAN)
RUN R -e "install.packages(c('SqlRender', 'DatabaseConnector'), repos='https://cloud.r-project.org/')"

# Install ETL-Synthea by cloning (avoids GitHub API rate limits)
RUN cd /tmp && \
    git clone --depth 1 https://github.com/OHDSI/ETLSyntheaBuilder.git && \
    R -e "remotes::install_local('/tmp/ETLSyntheaBuilder', upgrade='never', dependencies=FALSE)" && \
    rm -rf /tmp/ETLSyntheaBuilder

# Verify installation
RUN R -e "library(ETLSyntheaBuilder); cat('ETLSyntheaBuilder version:', as.character(packageVersion('ETLSyntheaBuilder')), '\n')"

# Set working directory
WORKDIR /app

# Default command
CMD ["R"]