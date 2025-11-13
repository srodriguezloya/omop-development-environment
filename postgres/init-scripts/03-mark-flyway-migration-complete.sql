-- First, create the Flyway metadata table if it doesn't exist
CREATE TABLE IF NOT EXISTS ohdsi.schema_version (
    installed_rank INT NOT NULL,
    version VARCHAR(50),
    description VARCHAR(200) NOT NULL,
    type VARCHAR(20) NOT NULL,
    script VARCHAR(1000) NOT NULL,
    checksum INT,
    installed_by VARCHAR(100) NOT NULL,
    installed_on TIMESTAMP NOT NULL DEFAULT NOW(),
    execution_time INT NOT NULL,
    success BOOLEAN NOT NULL,
    PRIMARY KEY (installed_rank)
    );

-- Mark the Spring Batch migration as already applied
INSERT INTO ohdsi.schema_version (
    installed_rank,
    version,
    description,
    type,
    script,
    checksum,
    installed_by,
    installed_on,
    execution_time,
    success
) VALUES (
             1,
             '1.0.0.1',
             'schema-create spring batch',
             'SQL',
             'V1.0.0.1__schema-create_spring_batch.sql',
             0,
             'ohdsi_admin',
             NOW(),
             0,
             true
         )
    ON CONFLICT (installed_rank) DO NOTHING;