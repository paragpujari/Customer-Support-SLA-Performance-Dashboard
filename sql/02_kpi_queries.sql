-- ============================================================
-- Customer Support & SLA Performance Dashboard
-- KPI Queries (SQL)
-- These can be used directly or as basis for Power BI measures / DirectQuery
-- ============================================================

-- ------------------------------------------------------------
-- 1. OVERALL VOLUME & BACKLOG
-- ------------------------------------------------------------

-- Total tickets created (all time or filtered by date in BI)
SELECT COUNT(*) AS total_tickets
FROM fact_tickets;

-- Open backlog (current open tickets)
SELECT COUNT(*) AS open_backlog
FROM fact_tickets
WHERE status IN ('Open', 'In Progress', 'Pending Customer');

-- Backlog by priority
SELECT
    p.priority_name,
    COUNT(*) AS open_tickets
FROM fact_tickets t
JOIN dim_priorities p ON t.priority_id = p.priority_id
WHERE t.status IN ('Open', 'In Progress', 'Pending Customer')
GROUP BY p.priority_name, p.priority_id
ORDER BY p.priority_id;

-- Backlog by team / agent
SELECT
    a.team,
    a.agent_name,
    COUNT(*) AS open_tickets
FROM fact_tickets t
JOIN dim_agents a ON t.agent_id = a.agent_id
WHERE t.status IN ('Open', 'In Progress', 'Pending Customer')
GROUP BY a.team, a.agent_name
ORDER BY a.team, open_tickets DESC;

-- ------------------------------------------------------------
-- 2. RESOLUTION TIME KPIs
-- ------------------------------------------------------------

-- Average & Median Resolution Time (hours) - overall
SELECT
    ROUND(AVG(resolution_hours), 2) AS avg_resolution_hours,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY resolution_hours), 2) AS median_resolution_hours,
    COUNT(*) AS resolved_tickets
FROM fact_tickets
WHERE resolution_hours IS NOT NULL;

-- Avg Resolution Time by Priority
SELECT
    p.priority_name,
    p.sla_resolution_hours AS sla_target_hours,
    ROUND(AVG(t.resolution_hours), 2) AS avg_resolution_hours,
    COUNT(*) AS tickets
FROM fact_tickets t
JOIN dim_priorities p ON t.priority_id = p.priority_id
WHERE t.resolution_hours IS NOT NULL
GROUP BY p.priority_name, p.sla_resolution_hours, p.priority_id
ORDER BY p.priority_id;

-- Avg Resolution Time by Category
SELECT
    c.category_name,
    ROUND(AVG(t.resolution_hours), 2) AS avg_resolution_hours,
    COUNT(*) AS tickets
FROM fact_tickets t
JOIN dim_categories c ON t.category_id = c.category_id
WHERE t.resolution_hours IS NOT NULL
GROUP BY c.category_name
ORDER BY avg_resolution_hours DESC;

-- Avg Resolution Time by Agent / Team
SELECT
    a.team,
    a.agent_name,
    ROUND(AVG(t.resolution_hours), 2) AS avg_resolution_hours,
    COUNT(*) AS resolved_tickets
FROM fact_tickets t
JOIN dim_agents a ON t.agent_id = a.agent_id
WHERE t.resolution_hours IS NOT NULL
GROUP BY a.team, a.agent_name
ORDER BY a.team, avg_resolution_hours;

-- ------------------------------------------------------------
-- 3. SLA COMPLIANCE
-- ------------------------------------------------------------

-- Overall Response SLA Compliance %
SELECT
    ROUND(100.0 * SUM(CASE WHEN first_response_hours <= p.sla_response_hours THEN 1 ELSE 0 END)
          / NULLIF(COUNT(*), 0), 2) AS response_sla_compliance_pct,
    COUNT(*) AS tickets_with_response
FROM fact_tickets t
JOIN dim_priorities p ON t.priority_id = p.priority_id
WHERE t.first_response_hours IS NOT NULL;

-- Overall Resolution SLA Compliance %
SELECT
    ROUND(100.0 * SUM(CASE WHEN resolution_hours <= p.sla_resolution_hours THEN 1 ELSE 0 END)
          / NULLIF(COUNT(*), 0), 2) AS resolution_sla_compliance_pct,
    COUNT(*) AS resolved_tickets
FROM fact_tickets t
JOIN dim_priorities p ON t.priority_id = p.priority_id
WHERE t.resolution_hours IS NOT NULL;

-- SLA Compliance by Priority
SELECT
    p.priority_name,
    ROUND(100.0 * SUM(CASE WHEN t.first_response_hours <= p.sla_response_hours THEN 1 ELSE 0 END)
          / NULLIF(COUNT(t.first_response_hours), 0), 2) AS response_sla_pct,
    ROUND(100.0 * SUM(CASE WHEN t.resolution_hours <= p.sla_resolution_hours THEN 1 ELSE 0 END)
          / NULLIF(COUNT(t.resolution_hours), 0), 2) AS resolution_sla_pct,
    COUNT(*) AS total_tickets
FROM fact_tickets t
JOIN dim_priorities p ON t.priority_id = p.priority_id
GROUP BY p.priority_name, p.priority_id
ORDER BY p.priority_id;

-- SLA Compliance by Agent
SELECT
    a.agent_name,
    a.team,
    ROUND(100.0 * SUM(CASE WHEN t.resolution_hours <= p.sla_resolution_hours THEN 1 ELSE 0 END)
          / NULLIF(COUNT(t.resolution_hours), 0), 2) AS resolution_sla_pct,
    COUNT(t.resolution_hours) AS resolved_count
FROM fact_tickets t
JOIN dim_agents a ON t.agent_id = a.agent_id
JOIN dim_priorities p ON t.priority_id = p.priority_id
WHERE t.resolution_hours IS NOT NULL
GROUP BY a.agent_name, a.team
ORDER BY resolution_sla_pct DESC;

-- ------------------------------------------------------------
-- 4. FIRST RESPONSE TIME
-- ------------------------------------------------------------

SELECT
    ROUND(AVG(first_response_hours), 2) AS avg_first_response_hours,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY first_response_hours), 2) AS median_first_response_hours
FROM fact_tickets
WHERE first_response_hours IS NOT NULL;

-- ------------------------------------------------------------
-- 5. CUSTOMER SATISFACTION (CSAT)
-- ------------------------------------------------------------

-- Overall CSAT
SELECT
    ROUND(AVG(csat_score), 2) AS avg_csat,
    COUNT(csat_score) AS responses,
    ROUND(100.0 * SUM(CASE WHEN csat_score >= 4 THEN 1 ELSE 0 END) / NULLIF(COUNT(csat_score), 0), 2) AS csat_good_pct  -- % 4 or 5
FROM fact_tickets
WHERE csat_score IS NOT NULL;

-- CSAT by Priority
SELECT
    p.priority_name,
    ROUND(AVG(t.csat_score), 2) AS avg_csat,
    COUNT(t.csat_score) AS responses
FROM fact_tickets t
JOIN dim_priorities p ON t.priority_id = p.priority_id
WHERE t.csat_score IS NOT NULL
GROUP BY p.priority_name, p.priority_id
ORDER BY p.priority_id;

-- CSAT by Agent
SELECT
    a.agent_name,
    a.team,
    ROUND(AVG(t.csat_score), 2) AS avg_csat,
    COUNT(t.csat_score) AS responses
FROM fact_tickets t
JOIN dim_agents a ON t.agent_id = a.agent_id
WHERE t.csat_score IS NOT NULL
GROUP BY a.agent_name, a.team
ORDER BY avg_csat DESC;

-- ------------------------------------------------------------
-- 6. TEAM PERFORMANCE
-- ------------------------------------------------------------

-- Tickets handled per agent (resolved)
SELECT
    a.team,
    a.agent_name,
    COUNT(*) AS tickets_resolved,
    ROUND(AVG(t.resolution_hours), 2) AS avg_resolution_hrs,
    ROUND(AVG(t.csat_score), 2) AS avg_csat
FROM fact_tickets t
JOIN dim_agents a ON t.agent_id = a.agent_id
WHERE t.status IN ('Resolved', 'Closed')
GROUP BY a.team, a.agent_name
ORDER BY a.team, tickets_resolved DESC;

-- ------------------------------------------------------------
-- 7. TRENDS (Monthly)
-- ------------------------------------------------------------

-- Tickets created & resolved by month
SELECT
    DATE_TRUNC('month', created_at) AS month,
    COUNT(*) AS tickets_created,
    SUM(CASE WHEN status IN ('Resolved', 'Closed') THEN 1 ELSE 0 END) AS tickets_resolved
FROM fact_tickets
GROUP BY DATE_TRUNC('month', created_at)
ORDER BY month;

-- Monthly SLA compliance trend
SELECT
    DATE_TRUNC('month', t.created_at) AS month,
    ROUND(100.0 * SUM(CASE WHEN t.resolution_hours <= p.sla_resolution_hours THEN 1 ELSE 0 END)
          / NULLIF(COUNT(t.resolution_hours), 0), 2) AS resolution_sla_pct,
    ROUND(AVG(t.resolution_hours), 2) AS avg_resolution_hrs
FROM fact_tickets t
JOIN dim_priorities p ON t.priority_id = p.priority_id
WHERE t.resolution_hours IS NOT NULL
GROUP BY DATE_TRUNC('month', t.created_at)
ORDER BY month;

-- ------------------------------------------------------------
-- 8. REOPEN RATE & ESCALATION
-- ------------------------------------------------------------

SELECT
    ROUND(100.0 * SUM(reopened) / NULLIF(COUNT(*), 0), 2) AS reopen_rate_pct,
    ROUND(100.0 * SUM(is_escalated) / NULLIF(COUNT(*), 0), 2) AS escalation_rate_pct
FROM fact_tickets
WHERE status IN ('Resolved', 'Closed');

-- ------------------------------------------------------------
-- 9. CHANNEL PERFORMANCE
-- ------------------------------------------------------------

SELECT
    ch.channel_name,
    COUNT(*) AS tickets,
    ROUND(AVG(t.resolution_hours), 2) AS avg_resolution_hrs,
    ROUND(AVG(t.csat_score), 2) AS avg_csat,
    ROUND(100.0 * SUM(CASE WHEN t.resolution_hours <= p.sla_resolution_hours THEN 1 ELSE 0 END)
          / NULLIF(COUNT(t.resolution_hours), 0), 2) AS resolution_sla_pct
FROM fact_tickets t
JOIN dim_channels ch ON t.channel_id = ch.channel_id
JOIN dim_priorities p ON t.priority_id = p.priority_id
GROUP BY ch.channel_name
ORDER BY tickets DESC;

-- ------------------------------------------------------------
-- 10. AGEING ANALYSIS (Open tickets)
-- ------------------------------------------------------------

SELECT
    CASE
        WHEN EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - created_at))/3600 <= 24 THEN '0-24 hrs'
        WHEN EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - created_at))/3600 <= 72 THEN '1-3 days'
        WHEN EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - created_at))/3600 <= 168 THEN '3-7 days'
        ELSE '7+ days'
    END AS age_bucket,
    COUNT(*) AS open_tickets
FROM fact_tickets
WHERE status IN ('Open', 'In Progress', 'Pending Customer')
GROUP BY 1
ORDER BY MIN(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - created_at))/3600);
