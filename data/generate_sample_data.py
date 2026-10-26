#!/usr/bin/env python3
"""
Generate realistic sample data for Customer Support & SLA Performance Dashboard.
Creates CSV files for tickets, agents, categories, priorities, and SLA policies.
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import random
import os

np.random.seed(42)
random.seed(42)

OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__))

# ============================================================
# 1. Agents / Support Team
# ============================================================
agents = [
    {"agent_id": 1, "agent_name": "Priya Sharma", "team": "Tier 1", "hire_date": "2023-01-15", "shift": "Morning"},
    {"agent_id": 2, "agent_name": "Rahul Verma", "team": "Tier 1", "hire_date": "2022-06-20", "shift": "Morning"},
    {"agent_id": 3, "agent_name": "Ananya Patel", "team": "Tier 1", "hire_date": "2023-03-10", "shift": "Evening"},
    {"agent_id": 4, "agent_name": "Vikram Singh", "team": "Tier 2", "hire_date": "2021-11-05", "shift": "Morning"},
    {"agent_id": 5, "agent_name": "Sneha Reddy", "team": "Tier 2", "hire_date": "2022-09-12", "shift": "Evening"},
    {"agent_id": 6, "agent_name": "Arjun Mehta", "team": "Tier 2", "hire_date": "2020-04-18", "shift": "Night"},
    {"agent_id": 7, "agent_name": "Kavita Nair", "team": "Tier 3", "hire_date": "2019-08-22", "shift": "Morning"},
    {"agent_id": 8, "agent_name": "Rohan Das", "team": "Tier 3", "hire_date": "2021-02-14", "shift": "Evening"},
]

agents_df = pd.DataFrame(agents)
agents_df.to_csv(os.path.join(OUTPUT_DIR, "dim_agents.csv"), index=False)
print(f"Created dim_agents.csv with {len(agents_df)} agents")

# ============================================================
# 2. Categories
# ============================================================
categories = [
    {"category_id": 1, "category_name": "Login / Access Issues", "parent_category": "Account"},
    {"category_id": 2, "category_name": "Billing & Payments", "parent_category": "Finance"},
    {"category_id": 3, "category_name": "Product Feature Request", "parent_category": "Product"},
    {"category_id": 4, "category_name": "Bug / Technical Error", "parent_category": "Technical"},
    {"category_id": 5, "category_name": "Performance / Latency", "parent_category": "Technical"},
    {"category_id": 6, "category_name": "Integration / API", "parent_category": "Technical"},
    {"category_id": 7, "category_name": "Account Upgrade / Downgrade", "parent_category": "Account"},
    {"category_id": 8, "category_name": "General Inquiry", "parent_category": "Support"},
]

categories_df = pd.DataFrame(categories)
categories_df.to_csv(os.path.join(OUTPUT_DIR, "dim_categories.csv"), index=False)
print(f"Created dim_categories.csv with {len(categories_df)} categories")

# ============================================================
# 3. Priorities & SLA Policies
# ============================================================
priorities = [
    {"priority_id": 1, "priority_name": "Critical", "sla_response_hours": 1, "sla_resolution_hours": 4, "color": "#DC2626"},
    {"priority_id": 2, "priority_name": "High", "sla_response_hours": 4, "sla_resolution_hours": 24, "color": "#F97316"},
    {"priority_id": 3, "priority_name": "Medium", "sla_response_hours": 8, "sla_resolution_hours": 72, "color": "#EAB308"},
    {"priority_id": 4, "priority_name": "Low", "sla_response_hours": 24, "sla_resolution_hours": 168, "color": "#22C55E"},
]

priorities_df = pd.DataFrame(priorities)
priorities_df.to_csv(os.path.join(OUTPUT_DIR, "dim_priorities.csv"), index=False)
print(f"Created dim_priorities.csv with {len(priorities_df)} priorities")

# ============================================================
# 4. Channels
# ============================================================
channels = [
    {"channel_id": 1, "channel_name": "Email"},
    {"channel_id": 2, "channel_name": "Chat"},
    {"channel_id": 3, "channel_name": "Phone"},
    {"channel_id": 4, "channel_name": "Portal"},
    {"channel_id": 5, "channel_name": "Social Media"},
]
channels_df = pd.DataFrame(channels)
channels_df.to_csv(os.path.join(OUTPUT_DIR, "dim_channels.csv"), index=False)
print(f"Created dim_channels.csv with {len(channels_df)} channels")

# ============================================================
# 5. Fact: Support Tickets (main fact table)
# ============================================================
N_TICKETS = 2500

# Date range: last 12 months
end_date = datetime(2026, 10, 25)
start_date = end_date - timedelta(days=365)

# Statuses
statuses = ["Open", "In Progress", "Pending Customer", "Resolved", "Closed"]
status_weights = [0.08, 0.12, 0.05, 0.25, 0.50]  # Most are closed/resolved

# Priority distribution (more medium/low)
priority_weights = [0.08, 0.18, 0.45, 0.29]

tickets = []
for i in range(1, N_TICKETS + 1):
    created = start_date + timedelta(
        days=np.random.randint(0, 365),
        hours=np.random.randint(0, 24),
        minutes=np.random.randint(0, 60)
    )
    
    priority_id = np.random.choice([1, 2, 3, 4], p=priority_weights)
    sla_resp = priorities_df.loc[priorities_df.priority_id == priority_id, "sla_response_hours"].values[0]
    sla_res = priorities_df.loc[priorities_df.priority_id == priority_id, "sla_resolution_hours"].values[0]
    
    # First response time (some miss SLA)
    if random.random() < 0.85:  # 85% meet response SLA
        first_response_hours = np.random.uniform(0.1, sla_resp * 0.9)
    else:
        first_response_hours = np.random.uniform(sla_resp * 1.05, sla_resp * 2.5)
    
    first_response_at = created + timedelta(hours=first_response_hours)
    
    # Resolution time
    status = np.random.choice(statuses, p=status_weights)
    
    if status in ["Resolved", "Closed"]:
        # Most meet resolution SLA, some don't
        if random.random() < 0.78:  # ~78% meet resolution SLA overall
            resolution_hours = np.random.uniform(first_response_hours + 0.5, sla_res * 0.95)
        else:
            resolution_hours = np.random.uniform(sla_res * 1.1, sla_res * 3.0)
        resolved_at = created + timedelta(hours=resolution_hours)
        closed_at = resolved_at + timedelta(hours=np.random.uniform(0.5, 24)) if status == "Closed" else None
    else:
        resolution_hours = None
        resolved_at = None
        closed_at = None
        # For open tickets, make them more recent
        if created < end_date - timedelta(days=30):
            created = end_date - timedelta(days=np.random.randint(0, 45))
            first_response_at = created + timedelta(hours=first_response_hours)
    
    agent_id = np.random.choice(agents_df.agent_id)
    # Tier 3 handles more critical
    if priority_id == 1 and random.random() < 0.6:
        agent_id = np.random.choice([7, 8])
    elif priority_id == 2 and random.random() < 0.4:
        agent_id = np.random.choice([4, 5, 6, 7, 8])
    
    category_id = np.random.choice(categories_df.category_id)
    channel_id = np.random.choice(channels_df.channel_id, p=[0.35, 0.30, 0.15, 0.15, 0.05])
    
    # Customer satisfaction (CSAT) only for resolved/closed
    csat = None
    if status in ["Resolved", "Closed"]:
        # Higher CSAT when SLA met
        met_res_sla = resolution_hours is not None and resolution_hours <= sla_res
        if met_res_sla:
            csat = np.random.choice([3, 4, 5], p=[0.10, 0.30, 0.60])
        else:
            csat = np.random.choice([1, 2, 3, 4, 5], p=[0.25, 0.30, 0.25, 0.15, 0.05])
    
    # Reopened flag
    reopened = 1 if (status in ["Resolved", "Closed"] and random.random() < 0.07) else 0
    
    tickets.append({
        "ticket_id": i,
        "ticket_number": f"TKT-{2025 + (created.year - 2025)}-{i:05d}",
        "created_at": created.strftime("%Y-%m-%d %H:%M:%S"),
        "first_response_at": first_response_at.strftime("%Y-%m-%d %H:%M:%S"),
        "resolved_at": resolved_at.strftime("%Y-%m-%d %H:%M:%S") if resolved_at else None,
        "closed_at": closed_at.strftime("%Y-%m-%d %H:%M:%S") if closed_at else None,
        "status": status,
        "priority_id": priority_id,
        "category_id": category_id,
        "channel_id": channel_id,
        "agent_id": agent_id,
        "customer_id": np.random.randint(1000, 9999),
        "subject": f"Issue related to {categories_df.loc[categories_df.category_id == category_id, 'category_name'].values[0]}",
        "first_response_hours": round(first_response_hours, 2),
        "resolution_hours": round(resolution_hours, 2) if resolution_hours else None,
        "csat_score": csat,
        "reopened": reopened,
        "is_escalated": 1 if (priority_id <= 2 and random.random() < 0.25) else 0,
    })

tickets_df = pd.DataFrame(tickets)

# Ensure open tickets are actually open (no resolved_at)
tickets_df.loc[tickets_df.status.isin(["Open", "In Progress", "Pending Customer"]), ["resolved_at", "closed_at", "resolution_hours", "csat_score"]] = None

tickets_df.to_csv(os.path.join(OUTPUT_DIR, "fact_tickets.csv"), index=False)
print(f"Created fact_tickets.csv with {len(tickets_df)} tickets")

# Quick stats
print("\n--- Sample Data Summary ---")
print(f"Date range: {tickets_df.created_at.min()} to {tickets_df.created_at.max()}")
print(f"Status distribution:\n{tickets_df.status.value_counts()}")
print(f"Priority distribution:\n{tickets_df.priority_id.value_counts().sort_index()}")
print(f"Avg resolution hours (resolved): {tickets_df.resolution_hours.mean():.1f}")
print(f"CSAT average: {tickets_df.csat_score.mean():.2f}")
print("Done.")
