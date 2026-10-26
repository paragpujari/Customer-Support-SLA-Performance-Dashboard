-- ============================================================
-- Customer Support & SLA Performance Dashboard
-- Database Schema (Star Schema)
-- Compatible with PostgreSQL / SQL Server / MySQL (minor syntax tweaks)
-- ============================================================

-- Dimension: Agents
CREATE TABLE dim_agents (
    agent_id        INT PRIMARY KEY,
    agent_name      VARCHAR(100) NOT NULL,
    team            VARCHAR(50)  NOT NULL,   -- Tier 1, Tier 2, Tier 3
    hire_date       DATE,
    shift           VARCHAR(20)
);

-- Dimension: Categories
CREATE TABLE dim_categories (
    category_id     INT PRIMARY KEY,
    category_name   VARCHAR(100) NOT NULL,
    parent_category VARCHAR(50)
);

-- Dimension: Priorities (includes SLA targets)
CREATE TABLE dim_priorities (
    priority_id           INT PRIMARY KEY,
    priority_name         VARCHAR(50) NOT NULL,
    sla_response_hours    DECIMAL(6,2) NOT NULL,
    sla_resolution_hours  DECIMAL(6,2) NOT NULL,
    color                 VARCHAR(10)
);

-- Dimension: Channels
CREATE TABLE dim_channels (
    channel_id    INT PRIMARY KEY,
    channel_name  VARCHAR(50) NOT NULL
);

-- Dimension: Date (optional but recommended for Power BI)
-- Can be generated in Power BI or loaded separately
CREATE TABLE dim_date (
    date_key      INT PRIMARY KEY,          -- YYYYMMDD
    full_date     DATE NOT NULL,
    year          INT,
    quarter       INT,
    month         INT,
    month_name    VARCHAR(20),
    week          INT,
    day_of_week   INT,
    day_name      VARCHAR(20),
    is_weekend    BOOLEAN
);

-- Fact: Support Tickets
CREATE TABLE fact_tickets (
    ticket_id             INT PRIMARY KEY,
    ticket_number         VARCHAR(20) NOT NULL,
    created_at            TIMESTAMP NOT NULL,
    first_response_at     TIMESTAMP,
    resolved_at           TIMESTAMP,
    closed_at             TIMESTAMP,
    status                VARCHAR(30) NOT NULL,
    priority_id           INT NOT NULL REFERENCES dim_priorities(priority_id),
    category_id           INT NOT NULL REFERENCES dim_categories(category_id),
    channel_id            INT NOT NULL REFERENCES dim_channels(channel_id),
    agent_id              INT NOT NULL REFERENCES dim_agents(agent_id),
    customer_id           INT,
    subject               VARCHAR(255),
    first_response_hours  DECIMAL(10,2),
    resolution_hours      DECIMAL(10,2),
    csat_score            INT CHECK (csat_score BETWEEN 1 AND 5),
    reopened              INT DEFAULT 0,
    is_escalated          INT DEFAULT 0
);

-- Indexes for performance
CREATE INDEX idx_tickets_created_at ON fact_tickets(created_at);
CREATE INDEX idx_tickets_status ON fact_tickets(status);
CREATE INDEX idx_tickets_priority ON fact_tickets(priority_id);
CREATE INDEX idx_tickets_agent ON fact_tickets(agent_id);
CREATE INDEX idx_tickets_category ON fact_tickets(category_id);
CREATE INDEX idx_tickets_resolved_at ON fact_tickets(resolved_at);

-- ============================================================
-- Useful Views for Analytics
-- ============================================================

-- View: Ticket with SLA flags and dimensions
CREATE OR REPLACE VIEW vw_tickets_enriched AS
SELECT
    t.ticket_id,
    t.ticket_number,
    t.created_at,
    t.first_response_at,
    t.resolved_at,
    t.closed_at,
    t.status,
    t.first_response_hours,
    t.resolution_hours,
    t.csat_score,
    t.reopened,
    t.is_escalated,
    t.customer_id,
    t.subject,
    -- Dimensions
    a.agent_name,
    a.team,
    a.shift,
    c.category_name,
    c.parent_category,
    p.priority_name,
    p.sla_response_hours,
    p.sla_resolution_hours,
    ch.channel_name,
    -- SLA Compliance Flags
    CASE
        WHEN t.first_response_hours IS NULL THEN NULL
        WHEN t.first_response_hours <= p.sla_response_hours THEN 1
        ELSE 0
    END AS met_response_sla,
    CASE
        WHEN t.resolution_hours IS NULL THEN NULL
        WHEN t.resolution_hours <= p.sla_resolution_hours THEN 1
        ELSE 0
    END AS met_resolution_sla,
    -- Derived metrics
    CASE
        WHEN t.status IN ('Open', 'In Progress', 'Pending Customer') THEN 1
        ELSE 0
    END AS is_open,
    CASE
        WHEN t.status IN ('Resolved', 'Closed') THEN 1
        ELSE 0
    END AS is_resolved,
    DATE(t.created_at) AS created_date,
    DATE(t.resolved_at) AS resolved_date
FROM fact_tickets t
JOIN dim_agents a ON t.agent_id = a.agent_id
JOIN dim_categories c ON t.category_id = c.category_id
JOIN dim_priorities p ON t.priority_id = p.priority_id
JOIN dim_channels ch ON t.channel_id = ch.channel_id;
