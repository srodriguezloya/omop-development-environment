FROM rocker/r-ver:4.3.2

# Install system dependencies including Java
RUN apt-get update && apt-get install -y \
    libpq-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    git \
    default-jdk \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Configure Java for R
RUN R CMD javareconf

# Create directory for JDBC drivers
RUN mkdir -p /opt/jdbc_drivers

# Download PostgreSQL JDBC driver
RUN wget -O /opt/jdbc_drivers/postgresql-42.7.1.jar https://jdbc.postgresql.org/download/postgresql-42.7.1.jar

# Install R packages (including all Shiny dependencies)
RUN R -e "install.packages(c('remotes', 'rJava', 'DatabaseConnector', 'SqlRender', 'jsonlite', 'httr', 'shiny', 'htmltools', 'httpuv', 'mime', 'sourcetools', 'xtable', 'fontawesome', 'bslib', 'cachem', 'sass', 'jquerylib'), repos='https://cloud.r-project.org/')"

# Install OHDSI packages
RUN R -e "remotes::install_github('OHDSI/DataQualityDashboard')"
RUN R -e "remotes::install_github('OHDSI/Eunomia')"

# Create working directory
WORKDIR /dqd

# Create directories for results and configuration
RUN mkdir -p /dqd/results /dqd/config

# Copy execution script
COPY run-dqd.R /dqd/run-dqd.R

# Expose port for Shiny app (if you want to view results interactively)
EXPOSE 3838

# Set Shiny host to listen on all interfaces
ENV SHINY_HOST=0.0.0.0

CMD ["R", "--vanilla", "-f", "/dqd/run-dqd.R"]