# Modern ETL-Synthea Dockerfile
FROM rocker/r-ver:4.4.1

# Install system dependencies INCLUDING Java
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
    default-jdk \
    && rm -rf /var/lib/apt/lists/*

# Configure Java for R
RUN R CMD javareconf

# Install base R packages
RUN R -e "install.packages('remotes', repos='https://cloud.r-project.org/')"
RUN R -e "install.packages(c('DBI', 'dplyr', 'readr'), repos='https://cloud.r-project.org/')"

# Install rJava explicitly first
RUN R -e "install.packages('rJava', repos='https://cloud.r-project.org/')"

# Install OHDSI packages
RUN R -e "install.packages('SqlRender', repos='https://cloud.r-project.org/')"
RUN R -e "install.packages('DatabaseConnector', repos='https://cloud.r-project.org/')"

# Install from GitHub
RUN R -e "remotes::install_github('OHDSI/CommonDataModel', upgrade='never')"
RUN R -e "remotes::install_github('OHDSI/ETL-Synthea', upgrade='never')"

# Verify
RUN R -e "library(ETLSyntheaBuilder); cat('SUCCESS: ETLSyntheaBuilder installed!\n')"

WORKDIR /app
CMD ["R"]