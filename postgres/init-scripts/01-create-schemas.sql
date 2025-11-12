-- Create OMOP schemas
CREATE SCHEMA IF NOT EXISTS ohdsi;
CREATE SCHEMA IF NOT EXISTS ohdsi_results;
CREATE SCHEMA IF NOT EXISTS webapi;

-- Grant permissions
GRANT ALL ON SCHEMA ohdsi TO ohdsi_admin;
GRANT ALL ON SCHEMA ohdsi_results TO ohdsi_admin;
GRANT ALL ON SCHEMA webapi TO ohdsi_admin;
