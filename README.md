# Supply Chain Performance Analysis

**Tools:** SQL (SQLite) · Excel · Power BI  
**Dataset:** 100 SKUs across haircare, skincare, and cosmetics product lines

## Project Overview
This project analyzes an end-to-end supply chain dataset to identify cost drivers, 
supplier quality issues, and logistics inefficiencies. The goal is to surface 
actionable recommendations that reduce cost and improve delivery performance.

## Business Questions Answered
- Which product categories generate the most revenue, and is pricing aligned with demand?
- Which suppliers have the highest defect rates and slowest lead times?
- Which shipping routes and carriers cost the most relative to revenue?
- Which SKUs are unprofitable when all supply chain costs are factored in?

## Key Findings
- Supplier 4 had a 0% inspection pass rate across 18 SKUs — the highest quality risk
- Supplier 1 outperformed all others with a 48% pass rate and lowest avg defect rate
- Road transport has the highest cost as % of revenue (10.2%) despite being most used
- Sea freight is the most cost-efficient mode at 7.4% cost-to-revenue ratio

## SQL Highlights
The analysis includes 13 queries across 5 sections:
- Revenue & sales overview with cumulative contribution analysis (window functions)
- Supplier scorecard with pass/fail rates and lead time benchmarking
- Logistics cost breakdown by carrier, route, and transport mode
- Estimated gross margin per SKU accounting for all known cost components
- Executive summary KPIs for dashboard use

## Files
| File | Description |
|------|-------------|
| `supply_chain_analysis.sql` | All 13 SQL queries with comments |
| `supply_chain_dashboard.xlsx` | Cleaned data, pivot tables, supplier scorecard |
| `supply_chain_dashboard.pbix` | Power BI dashboard (3 report pages) |
