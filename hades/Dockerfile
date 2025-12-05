# hades/Dockerfile
FROM rocker/r-ver:4.4.1

# Install system dependencies
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

# Configure Java
RUN R CMD javareconf

# Install core HADES dependencies
RUN R -e "install.packages('remotes', repos='https://cloud.r-project.org/')"
RUN R -e "install.packages('DatabaseConnector', repos='https://cloud.r-project.org/')"
RUN R -e "install.packages('SqlRender', repos='https://cloud.r-project.org/')"
RUN R -e "install.packages('rJava', repos='https://cloud.r-project.org/')"

# Install HADES characterization packages
RUN R -e "install.packages('Achilles', repos='https://cloud.r-project.org/')"  # On CRAN!
RUN R -e "remotes::install_github('OHDSI/DataQualityDashboard', upgrade='never')"
RUN R -e "remotes::install_github('OHDSI/AresIndexer', upgrade='never')"

# Download JDBC drivers
RUN mkdir -p /opt/jdbc && \
    wget -O /opt/jdbc/postgresql-42.7.4.jar \
    https://jdbc.postgresql.org/download/postgresql-42.7.4.jar

ENV DATABASECONNECTOR_JAR_FOLDER=/opt/jdbc

WORKDIR /app

CMD ["R"]