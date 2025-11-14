# Custom OHDSI ETL-Synthea Image (v2.1.0, ARM64-Safe)
FROM rocker/r-ver:4.4.1

# Install system dependencies (Java + libs for rJava/OHDSI)
USER root
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
        openjdk-11-jdk \
        liblzma-dev \
        libbz2-dev \
        libpcre2-dev \
        libcurl4-openssl-dev \
        libicu-dev \
        libssl-dev \
        libxml2-dev \
        r-cran-rmarkdown && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Switch to R user and install R packages step-by-step (ARM64-safe)
USER 1000

# Step 1: Core R deps + rJava (with --no-multiarch for ARM64)
RUN R -e "\
  options(repos = 'https://cran.r-project.org', Ncpus = parallel::detectCores()); \
  install.packages(c('remotes', 'DBI'), dependencies = TRUE); \
  install.packages('rJava', dependencies = TRUE, INSTALL_opts = '--no-multiarch') \
"

# Step 2: Reconfigure Java after rJava install
RUN R CMD javareconf

# Step 3: Install OHDSI packages from GitHub (latest master, no deps to avoid loops)
RUN R -e "\
  options(repos = 'https://cran.r-project.org', Ncpus = parallel::detectCores()); \
  remotes::install_github(c( \
    'OHDSI/SqlRender@master', \
    'OHDSI/DatabaseConnector@master', \
    'OHDSI/ETLSyntheaBuilder@master' \
  ), upgrade = 'never', dependencies = FALSE); \
  library(ETLSyntheaBuilder); \
  cat('ETLSyntheaBuilder version:', as.character(packageVersion('ETLSyntheaBuilder')), '\\n') \
"

# Set working directory
WORKDIR /app

# Default command (overridden in compose)
CMD ["Rscript", "-e", "cat('ETL-Synthea Ready!'); q()"]