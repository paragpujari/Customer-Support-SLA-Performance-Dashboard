# Data Dictionary  
## Customer Support & SLA Performance Dashboard

This document describes all tables, columns, relationships, and business rules used in the data model.

---

## 1. Data Model Overview (Star Schema)

```
                    ┌─────────────────┐
                    │  dim_priorities │
                    └────────┬────────┘
                             │
┌──────────────┐    ┌────────▼────────┐    ┌─────────────────┐
│  dim_agents  │◄───│  fact_tickets   │───►│ dim_categories  │
└──────────────┘    └────────┬────────┘    └─────────────────┘
                             │
                    ┌────────▼────────┐
                    │  dim_channels   │
                    └─────────────────┘
```

**Fact Table**: `fact_tickets` (grain = one row per support ticket)  
**Dimensions**: Agents, Categories, Priorities (with SLA targets), Channels, Date (recommended)

---

## 2. Dimension Tables

### dim_agents
| Column       | Data Type   | Description                                      | Example          |
|--------------|-------------|--------------------------------------------------|------------------|
| agent_id     | INT (PK)    | Unique identifier for support agent              | 1                |
| agent_name   | VARCHAR     | Full name of the agent                           | Priya Sharma     |
| team         | VARCHAR     | Support tier: Tier 1 / Tier 2 / Tier 3           | Tier 1           |
| hire_date    | DATE        | Date the agent joined the company                | 2023-01-15       |
| shift        | VARCHAR     | Work shift: Morning / Evening / Night            | Morning          |

### dim_categories
| Column          | Data Type | Description                                      | Example                  |
|-----------------|-----------|--------------------------------------------------|--------------------------|
| category_id     | INT (PK)  | Unique category identifier                       | 4                        |
| category_name   | VARCHAR   | Detailed issue category                          | Bug / Technical Error    |
| parent_category | VARCHAR   | High-level grouping                              | Technical                |

### dim_priorities
| Column                | Data Type   | Description                                      | Example     |
|-----------------------|-------------|--------------------------------------------------|-------------|
| priority_id           | INT (PK)    | Unique priority identifier                       | 1           |
| priority_name         | VARCHAR     | Critical / High / Medium / Low                   | Critical    |
| sla_response_hours    | DECIMAL     | Target hours for first response                  | 1           |
| sla_resolution_hours  | DECIMAL     | Target hours for full resolution                 | 4           |
| color                 | VARCHAR     | Hex color for visual encoding in dashboards      | #DC2626     |

**SLA Targets (Business Rules)**:
| Priority  | Response SLA | Resolution SLA |
|-----------|--------------|----------------|
| Critical  | 1 hour       | 4 hours        |
| High      | 4 hours      | 24 hours       |
| Medium    | 8 hours      | 72 hours       |
| Low       | 24 hours     | 168 hours (7 days) |

### dim_channels
| Column       | Data Type | Description                          | Example    |
|--------------|-----------|--------------------------------------|------------|
| channel_id   | INT (PK)  | Unique channel identifier            | 2          |
| channel_name | VARCHAR   | Email / Chat / Phone / Portal / Social Media | Chat |

---

## 3. Fact Table: fact_tickets

| Column               | Data Type   | Description                                                                 | Nullable |
|----------------------|-------------|-----------------------------------------------------------------------------|----------|
| ticket_id            | INT (PK)    | Surrogate key                                                               | No       |
| ticket_number        | VARCHAR     | Business key (e.g., TKT-2026-00042)                                         | No       |
| created_at           | TIMESTAMP   | When the ticket was logged                                                  | No       |
| first_response_at    | TIMESTAMP   | When the agent first replied                                                | Yes      |
| resolved_at          | TIMESTAMP   | When the ticket was marked Resolved                                         | Yes      |
| closed_at            | TIMESTAMP   | When the ticket was closed (after resolution)                               | Yes      |
| status               | VARCHAR     | Open / In Progress / Pending Customer / Resolved / Closed                   | No       |
| priority_id          | INT (FK)    | References dim_priorities                                                   | No       |
| category_id          | INT (FK)    | References dim_categories                                                   | No       |
| channel_id           | INT (FK)    | References dim_channels                                                     | No       |
| agent_id             | INT (FK)    | References dim_agents (current owner)                                       | No       |
| customer_id          | INT         | Anonymous customer identifier                                               | Yes      |
| subject              | VARCHAR     | Short description of the issue                                              | Yes      |
| first_response_hours | DECIMAL     | Calculated: hours from created_at to first_response_at                      | Yes      |
| resolution_hours     | DECIMAL     | Calculated: hours from created_at to resolved_at                            | Yes      |
| csat_score           | INT         | Customer satisfaction rating (1–5). Only for Resolved/Closed tickets        | Yes      |
| reopened             | INT         | 1 if ticket was reopened after resolution, else 0                           | No       |
| is_escalated         | INT         | 1 if escalated to higher tier, else 0                                       | No       |

---

## 4. Calculated / Derived Fields (used in views & Power BI)

| Field                 | Logic                                                                 | Purpose                          |
|-----------------------|-----------------------------------------------------------------------|----------------------------------|
| met_response_sla      | first_response_hours ≤ sla_response_hours                             | Response SLA flag (1/0)          |
| met_resolution_sla    | resolution_hours ≤ sla_resolution_hours                               | Resolution SLA flag (1/0)        |
| is_open               | status IN ('Open', 'In Progress', 'Pending Customer')                 | Backlog flag                     |
| is_resolved           | status IN ('Resolved', 'Closed')                                      | Volume of resolved work          |
| created_date          | DATE(created_at)                                                      | For daily/monthly aggregation    |
| age_hours             | EXTRACT(EPOCH FROM (NOW() - created_at))/3600 for open tickets        | Ageing analysis                  |

---

## 5. Key Business Rules

1. **SLA Clock** starts at `created_at`.
2. **Response SLA** is measured to the first agent response.
3. **Resolution SLA** is measured to the moment the ticket is set to Resolved.
4. CSAT is collected only after resolution/closure.
5. Tickets in “Pending Customer” still count toward backlog but the SLA clock may be paused in real systems (simplified here – clock continues).
6. Reopened tickets keep their original `created_at` for historical SLA calculation.
7. One agent is assigned per ticket at any time (current owner).

---

## 6. Relationships (Cardinality)

- dim_agents → fact_tickets : 1:N
- dim_categories → fact_tickets : 1:N
- dim_priorities → fact_tickets : 1:N
- dim_channels → fact_tickets : 1:N

All relationships are many-to-one from the fact table.

---

*Document version: 1.0 | Generated for the Customer Support & SLA Performance Dashboard project*
