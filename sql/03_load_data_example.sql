-- Example load script (PostgreSQL style)
-- Adjust paths and syntax for your RDBMS

-- COPY or bulk insert the CSVs after creating tables with 01_schema.sql

COPY dim_agents FROM '/path/to/data/dim_agents.csv' CSV HEADER;
COPY dim_categories FROM '/path/to/data/dim_categories.csv' CSV HEADER;
COPY dim_priorities FROM '/path/to/data/dim_priorities.csv' CSV HEADER;
COPY dim_channels FROM '/path/to/data/dim_channels.csv' CSV HEADER;
COPY fact_tickets FROM '/path/to/data/fact_tickets.csv' CSV HEADER;

-- For SQL Server use BULK INSERT
-- For MySQL use LOAD DATA INFILE
-- For SQLite you can use .import in the CLI
