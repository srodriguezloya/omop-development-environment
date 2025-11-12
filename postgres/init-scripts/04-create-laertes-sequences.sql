-- postgres/init-scripts/04-fix-laertes-webapi-sequences.sql
-- This is the ONLY thing that works with WebAPI 2.15.0

-- Flyway runs with search_path = webapi
-- So we MUST create the sequences there with lowercase names
CREATE SEQUENCE IF NOT EXISTS webapi.laertes_summary_sequence;
CREATE SEQUENCE IF NOT EXISTS webapi.drug_hoi_evidence_sequence;
CREATE SEQUENCE IF NOT EXISTS webapi.evidence_sources_sequence;

-- Also create them in ohdsi for the app (optional but clean)
CREATE SEQUENCE IF NOT EXISTS ohdsi.LAERTES_SUMMARY_SEQUENCE;
CREATE SEQUENCE IF NOT EXISTS ohdsi.DRUG_HOI_EVIDENCE_SEQUENCE;
CREATE SEQUENCE IF NOT EXISTS ohdsi.EVIDENCE_SOURCES_SEQUENCE;

-- Grant access
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA webapi TO ohdsi_admin;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA ohdsi TO ohdsi_admin;

RAISE NOTICE 'Laertes sequences created in webapi (for Flyway) and ohdsi (for app)';