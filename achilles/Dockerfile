# Achilles Dockerfile
FROM rocker/r-ver:4.4.1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libpq-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    default-jdk \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Configure Java for R
RUN R CMD javareconf

# Install R packages
RUN R -e "install.packages(c('remotes', 'DatabaseConnector', 'SqlRender'), repos='https://cloud.r-project.org/')"

# Install Achilles
RUN R -e "remotes::install_github('OHDSI/Achilles', upgrade='never')"

# Download PostgreSQL JDBC driver
RUN mkdir -p /opt/jdbc && \
    wget -O /opt/jdbc/postgresql-42.7.4.jar https://jdbc.postgresql.org/download/postgresql-42.7.4.jar

ENV DATABASECONNECTOR_JAR_FOLDER=/opt/jdbc

WORKDIR /app
CMD ["R"]