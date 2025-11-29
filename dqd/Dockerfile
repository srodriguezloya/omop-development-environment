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

# Install base R packages one by one to ensure they all install
RUN R -e "install.packages('remotes', repos='https://cloud.r-project.org/')"
RUN R -e "install.packages('rJava', repos='https://cloud.r-project.org/')"
RUN R -e "install.packages('DatabaseConnector', repos='https://cloud.r-project.org/')"
RUN R -e "install.packages('SqlRender', repos='https://cloud.r-project.org/')"
RUN R -e "install.packages('jsonlite', repos='https://cloud.r-project.org/')"
RUN R -e "install.packages('httr', repos='https://cloud.r-project.org/')"
RUN R -e "install.packages('shiny', repos='https://cloud.r-project.org/')"
RUN R -e "install.packages('DT', repos='https://cloud.r-project.org/')"

# Verify shiny is installed
RUN R -e "if (!require('shiny')) stop('Shiny installation failed')"

# Install OHDSI packages
RUN R -e "remotes::install_github('OHDSI/DataQualityDashboard')"
RUN R -e "remotes::install_github('OHDSI/Eunomia')"

# Create working directory
WORKDIR /dqd

# Create directories for results and configuration
RUN mkdir -p /dqd/results /dqd/config

# Copy execution scripts
COPY run-dqd.R /dqd/run-dqd.R
COPY view-dqd-shiny.R /dqd/view-dqd-shiny.R

# Expose port for Shiny app
EXPOSE 3838

CMD ["R", "--vanilla", "-f", "/dqd/run-dqd.R"]