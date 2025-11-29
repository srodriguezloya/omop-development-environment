# DQD Dockerfile
FROM rocker/r-ver:4.4.1

# Install system dependencies including Java
RUN apt-get update && apt-get install -y \
    libpq-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    default-jdk \
    wget \
    libpcre2-dev \
    zlib1g-dev \
    libbz2-dev \
    liblzma-dev \
    libdeflate-dev \
    && rm -rf /var/lib/apt/lists/*

# Configure Java for R
RUN R CMD javareconf

# Install base R packages
RUN R -e "install.packages('remotes', repos='https://cloud.r-project.org/')"
RUN R -e "install.packages('DatabaseConnector', repos='https://cloud.r-project.org/')"
RUN R -e "install.packages('SqlRender', repos='https://cloud.r-project.org/')"
RUN R -e "install.packages('shiny', repos='https://cloud.r-project.org/')"

# Install DQD
RUN R -e "remotes::install_github('OHDSI/DataQualityDashboard', upgrade='never')"

# Download PostgreSQL JDBC driver
RUN mkdir -p /opt/jdbc && \
    wget -O /opt/jdbc/postgresql-42.7.4.jar https://jdbc.postgresql.org/download/postgresql-42.7.4.jar

ENV DATABASECONNECTOR_JAR_FOLDER=/opt/jdbc

# Set Shiny server configuration
ENV SHINY_LOG_STDERR=1

WORKDIR /app

# Create directories for results and configuration
RUN mkdir results config

# Expose port for Shiny app
EXPOSE 3838

CMD ["R"]