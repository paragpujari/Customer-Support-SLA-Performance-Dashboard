# Power BI Implementation Guide  
## Customer Support & SLA Performance Dashboard

---

## 1. Data Import Steps

1. Open **Power BI Desktop**.
2. **Get Data → Text/CSV** (or Folder if using multiple files).
3. Load the following files from the `/data` folder:
   - `fact_tickets.csv`
   - `dim_agents.csv`
   - `dim_categories.csv`
   - `dim_priorities.csv`
   - `dim_channels.csv`
4. In **Power Query Editor**:
   - Set correct data types (especially dates → Date/Time, hours → Decimal Number).
   - Create a **Date table** (recommended):
     ```
     Calendar = CALENDAR(MIN(fact_tickets[created_at]), MAX(fact_tickets[created_at]))
     ```
   - Add columns: Year, Month, MonthName, Quarter, Weekday, etc.
5. Close & Apply.

---

## 2. Data Model Relationships

In Model view, create the following relationships (all Many-to-One, single direction):

| From (Fact)              | To (Dimension)       | Cardinality |
|--------------------------|----------------------|-------------|
| fact_tickets[agent_id]   | dim_agents[agent_id] | Many : 1    |
| fact_tickets[category_id]| dim_categories[category_id] | Many : 1 |
| fact_tickets[priority_id]| dim_priorities[priority_id] | Many : 1 |
| fact_tickets[channel_id] | dim_channels[channel_id] | Many : 1 |
| fact_tickets[created_at] | Calendar[Date]       | Many : 1 (use date part) |

Mark the Calendar table as a **Date Table**.

---

## 3. Recommended DAX Measures

Paste these into a new measure table (e.g., `_Measures`).

```dax
-- Volume
Total Tickets = COUNTROWS(fact_tickets)

Open Backlog = 
CALCULATE(
    COUNTROWS(fact_tickets),
    fact_tickets[status] IN {"Open", "In Progress", "Pending Customer"}
)

Resolved Tickets = 
CALCULATE(
    COUNTROWS(fact_tickets),
    fact_tickets[status] IN {"Resolved", "Closed"}
)

-- Resolution Time
Avg Resolution Hours = 
AVERAGE(fact_tickets[resolution_hours])

Median Resolution Hours = 
MEDIAN(fact_tickets[resolution_hours])

-- Response Time
Avg First Response Hours = 
AVERAGE(fact_tickets[first_response_hours])

-- SLA Compliance
Response SLA % = 
VAR Met = 
    CALCULATE(
        COUNTROWS(fact_tickets),
        FILTER(
            fact_tickets,
            fact_tickets[first_response_hours] <= RELATED(dim_priorities[sla_response_hours])
        )
    )
VAR Total = COUNTROWS(FILTER(fact_tickets, NOT ISBLANK(fact_tickets[first_response_hours])))
RETURN DIVIDE(Met, Total)

Resolution SLA % = 
VAR Met = 
    CALCULATE(
        COUNTROWS(fact_tickets),
        FILTER(
            fact_tickets,
            fact_tickets[resolution_hours] <= RELATED(dim_priorities[sla_resolution_hours])
        )
    )
VAR Total = COUNTROWS(FILTER(fact_tickets, NOT ISBLANK(fact_tickets[resolution_hours])))
RETURN DIVIDE(Met, Total)

-- CSAT
Avg CSAT = AVERAGE(fact_tickets[csat_score])

CSAT Good % = 
DIVIDE(
    CALCULATE(COUNTROWS(fact_tickets), fact_tickets[csat_score] >= 4),
    CALCULATE(COUNTROWS(fact_tickets), NOT ISBLANK(fact_tickets[csat_score]))
)

-- Other
Reopen Rate = AVERAGE(fact_tickets[reopened])
Escalation Rate = AVERAGE(fact_tickets[is_escalated])
```

**Note**: The `RELATED` function works when the relationship is active. Alternative approach using `LOOKUPVALUE` or calculated columns for SLA flags is also common and often more performant.

### Recommended Calculated Columns on fact_tickets

```dax
Met Response SLA = 
IF(
    fact_tickets[first_response_hours] <= RELATED(dim_priorities[sla_response_hours]),
    1, 0
)

Met Resolution SLA = 
IF(
    ISBLANK(fact_tickets[resolution_hours]),
    BLANK(),
    IF(fact_tickets[resolution_hours] <= RELATED(dim_priorities[sla_resolution_hours]), 1, 0)
)

Is Open = 
IF(fact_tickets[status] IN {"Open", "In Progress", "Pending Customer"}, 1, 0)
```

Then measures become simpler:
```dax
Resolution SLA % = AVERAGE(fact_tickets[Met Resolution SLA])
```

---

## 4. Suggested Dashboard Pages & Visuals

### Page 1 – Executive Overview
- **KPI Cards** (row): Total Tickets | Open Backlog | Resolution SLA % | Avg CSAT | Avg Resolution Hrs
- **Line chart**: Tickets Created vs Resolved by Month
- **Clustered bar**: Open Backlog by Priority (color-coded)
- **Donut**: Status distribution
- **Gauge or KPI**: Resolution SLA % vs Target (85%)

### Page 2 – SLA Performance
- **Matrix**: Priority × Month with Resolution SLA %
- **Bar chart**: Resolution SLA % by Agent (sorted)
- **Scatter**: Avg Resolution Hours vs Volume by Category
- **Ageing funnel / stacked bar**: Open tickets by age bucket (0-24h, 1-3d, 3-7d, 7d+)

### Page 3 – Team Performance
- **Table or Matrix**: Agent | Team | Tickets Resolved | Avg Resolution Hrs | Resolution SLA % | Avg CSAT
- **Conditional formatting** on SLA % and CSAT
- **Scatter plot**: Volume (X) vs SLA % (Y) – bubble size = CSAT

### Page 4 – Category & Channel
- **Treemap** or **Bar**: Tickets by Category
- **Clustered column**: Avg Resolution Hours by Channel
- **Line + Column**: Volume and SLA by Channel over time

### Page 5 – Customer Experience
- **KPI**: Avg CSAT + CSAT Good %
- **Histogram / Column**: CSAT distribution (1–5)
- **Line**: CSAT trend by month
- **Table**: Reopened tickets analysis

---

## 5. Filters & Slicers (Recommended)

Always add these slicers on every page (or use Sync Slicers):
- Date range (created_at)
- Priority
- Team / Agent
- Category
- Channel
- Status

---

## 6. Color Guidelines

Use the colors defined in `dim_priorities`:
- Critical → #DC2626 (Red)
- High → #F97316 (Orange)
- Medium → #EAB308 (Yellow/Amber)
- Low → #22C55E (Green)

CSAT: Red (1-2) → Amber (3) → Green (4-5)

---

## 7. Performance Tips

- Prefer calculated columns for SLA flags when dataset is < 1M rows.
- Use **Import mode** for this size of data.
- Create a dedicated measures table.
- Hide technical columns (IDs) from the report view.
- Add descriptions to measures and tables for the documentation pane.

---

*This guide enables a fully functional Power BI dashboard using the provided sample data and SQL logic.*
