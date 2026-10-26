# Customer Support & SLA Performance Dashboard  
**End-to-End Analytics Project**

---

## Project Overview

This is a complete, production-ready style project that demonstrates how to build a **Customer Support & SLA Performance Dashboard** using:

- **SQL** – Schema design (star schema), KPI queries, and analytical views  
- **Data Modeling** – Dimensional modeling best practices  
- **Power BI** – Dashboard design, DAX measures, and visualization recommendations  
- **Business Insights** – Actionable findings derived from the sample data  

The project includes realistic sample data (2,500 support tickets over 12 months) so you can immediately explore the metrics and build the dashboard yourself.

---

## Folder Structure

```
Customer_Support_SLA_Dashboard/
│
├── data/
│   ├── fact_tickets.csv          # Main fact table (2,500 tickets)
│   ├── dim_agents.csv            # Support agents (8)
│   ├── dim_categories.csv        # Issue categories (8)
│   ├── dim_priorities.csv        # Priorities + SLA targets
│   ├── dim_channels.csv          # Contact channels
│   └── generate_sample_data.py   # Script to regenerate sample data
│
├── sql/
│   ├── 01_schema.sql             # Full star-schema DDL + enriched view
│   └── 02_kpi_queries.sql        # 10+ ready-to-run KPI queries
│
├── docs/
│   ├── data_dictionary.md        # Complete data dictionary
│   ├── business_insights.md      # Detailed findings & recommendations
│   └── power_bi_guide.md         # Step-by-step Power BI implementation + DAX
│
├── images/
│   ├── dashboard_executive_overview.png
│   ├── dashboard_team_performance.png
│   └── dashboard_sla_deepdive.png
│
├── dashboard/                    # Placeholder for .pbix file (create yourself)
│
└── README.md                     # This file
```

---

## Key Deliverables

| Deliverable              | Location                          | Description |
|--------------------------|-----------------------------------|-------------|
| **KPI Queries**          | `sql/02_kpi_queries.sql`          | Volume, backlog, resolution time, SLA compliance, CSAT, team performance, trends, ageing |
| **Data Model**           | `sql/01_schema.sql` + dictionary  | Star schema with fact_tickets + 4 dimensions |
| **Data Dictionary**      | `docs/data_dictionary.md`         | Full column-level documentation + business rules |
| **Business Insights**    | `docs/business_insights.md`       | Executive summary, findings, and prioritized recommendations |
| **Power BI Guide**       | `docs/power_bi_guide.md`          | Import steps, relationships, DAX measures, page layouts |
| **Dashboard Visuals**    | `images/`                         | Sample dashboard screenshots generated from the data |
| **Sample Data**          | `data/*.csv`                      | Ready to load into SQL or Power BI |

---

## How to Use

### Option A – Power BI (Recommended for Dashboard)

1. Open Power BI Desktop.
2. Import all CSV files from the `data/` folder.
3. Follow the relationships and DAX measures in `docs/power_bi_guide.md`.
4. Recreate the pages using the layout suggestions and the sample images in `images/` as reference.

### Option B – SQL Database

1. Create a database (PostgreSQL, SQL Server, MySQL, or SQLite).
2. Run `sql/01_schema.sql` to create tables and the enriched view.
3. Load the CSV files (or use the Python generator).
4. Execute the queries in `sql/02_kpi_queries.sql`.

### Option C – Explore Data with Python / Excel

Simply open the CSVs in Excel, Python (pandas), or any BI tool.

---

## Core KPIs Covered

- Ticket volume & open backlog
- Average / Median resolution time
- First-response time
- **Response SLA compliance %**
- **Resolution SLA compliance %**
- CSAT (average + % good)
- Reopen rate & escalation rate
- Agent & team performance scorecards
- Category and channel analysis
- Ticket ageing analysis
- Monthly trends

---

## SLA Policy (as modeled)

| Priority  | Response Target | Resolution Target |
|-----------|-----------------|-------------------|
| Critical  | 1 hour          | 4 hours           |
| High      | 4 hours         | 24 hours          |
| Medium    | 8 hours         | 72 hours          |
| Low       | 24 hours        | 7 days (168 hrs)  |

---

## Sample Insights Snapshot

- Resolution SLA compliance: **~79%** (target ≥ 85%)
- Open backlog: **~24%** of total tickets
- Average CSAT: **4.08**
- Critical tickets have the lowest SLA compliance despite good average resolution time → long-tail problem
- Portal channel performs best on both speed and SLA

See `docs/business_insights.md` for the full analysis and recommendations.

---

## Regenerating Sample Data

```bash
cd data
python3 generate_sample_data.py
```

You can change `N_TICKETS`, date ranges, or SLA hit rates inside the script.

---

## Next Steps / Extensions

- Connect to a real ticketing system (Zendesk, Freshdesk, ServiceNow, Jira Service Management) via API or database.
- Add agent utilization / handle-time metrics.
- Implement real-time streaming with Power BI streaming datasets.
- Build an automated alert when Critical backlog exceeds a threshold.
- Add customer segment or product-line dimensions.

---

## License & Usage

This project is provided for educational and portfolio purposes.  
You are free to use, modify, and showcase it in interviews or demos.

---

**Built as a complete end-to-end analytics project demonstrating SQL, dimensional modeling, KPI design, and Power BI dashboard development.**
