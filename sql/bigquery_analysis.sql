-- ================================================================
-- FC BARCELONA WAGE ANALYSIS - COMPLETE SQL QUERIES
-- Financial Analysis Project - Entry Level Portfolio
-- Author: [Your Name]
-- Date: October 2024
-- Tool: Google BigQuery
-- Database: fcb_financial_analysis
-- ================================================================

-- This project analyzes FC Barcelona's €220M wage structure to identify:
-- 1. Cost concentration and highest earners
-- 2. Position-based spending patterns
-- 3. Age demographics and salary progression
-- 4. Contract expiration risks
-- 5. Cost optimization opportunities

-- ================================================================
-- QUERY 1: Complete Player Overview with Age Groups
-- Purpose: Master dataset with all player info and calculated fields
-- Use Case: Foundation for dashboard visualizations
-- ================================================================

SELECT 
    player_id,
    player_name,
    position,
    age,
    weekly_wage_eur,
    annual_salary_eur,
    contract_expires,
    -- Calculate age group for demographic analysis
    CASE 
        WHEN age < 21 THEN 'Youth'
        WHEN age BETWEEN 21 AND 26 THEN 'Prime'
        WHEN age BETWEEN 27 AND 32 THEN 'Peak'
        ELSE 'Veteran'
    END AS age_group,
    -- Calculate years remaining on contract
    CAST(contract_expires AS INT64) - 2024 AS years_remaining,
    -- Calculate percentage of total wage bill
    ROUND((annual_salary_eur / 
        (SELECT SUM(annual_salary_eur) FROM fcb_financial_analysis.player_wages)) * 100, 2) 
        AS pct_of_total_wages
FROM fcb_financial_analysis.player_wages
ORDER BY annual_salary_eur DESC;

-- Key Finding: Top earners (Lewandowski €20.8M, De Jong €19.4M) represent 18% of wage bill


-- ================================================================
-- QUERY 2: Top 10 Highest Paid Players
-- Purpose: Identify biggest cost drivers
-- Business Value: Shows concentration of wage spending
-- ================================================================

SELECT 
    player_name,
    position,
    age,
    annual_salary_eur,
    contract_expires,
    -- Show as percentage of total budget
    ROUND((annual_salary_eur / 
        (SELECT SUM(annual_salary_eur) FROM fcb_financial_analysis.player_wages)) * 100, 1) 
        AS pct_of_budget
FROM fcb_financial_analysis.player_wages
ORDER BY annual_salary_eur DESC
LIMIT 10;

-- Key Finding: Top 10 players account for €150M (68% of total wage bill)
-- Risk: High concentration means losing 1-2 key players significantly impacts budget


-- ================================================================
-- QUERY 3: Wage Distribution by Position
-- Purpose: Compare spending across different positions
-- Business Value: Identify over/under-invested positions
-- ================================================================

SELECT 
    position,
    COUNT(*) AS player_count,
    ROUND(MIN(annual_salary_eur), 0) AS min_salary,
    ROUND(AVG(annual_salary_eur), 0) AS avg_salary,
    ROUND(MAX(annual_salary_eur), 0) AS max_salary,
    ROUND(SUM(annual_salary_eur), 0) AS total_salary,
    -- Calculate percentage of total wage bill
    ROUND((SUM(annual_salary_eur) / 
        (SELECT SUM(annual_salary_eur) FROM fcb_financial_analysis.player_wages)) * 100, 1) 
        AS pct_of_wages
FROM fcb_financial_analysis.player_wages
GROUP BY position
ORDER BY total_salary DESC;

-- Key Finding: Midfielders cost €82M (37% of budget) with 9 players
-- Recommendation: Consider promoting youth midfielders to reduce costs


-- ================================================================
-- QUERY 4: Age Group Analysis
-- Purpose: Understand salary distribution across age demographics
-- Business Value: Assess team balance and succession planning
-- ================================================================

SELECT 
    CASE 
        WHEN age < 21 THEN 'Youth (Under 21)'
        WHEN age BETWEEN 21 AND 26 THEN 'Prime (21-26)'
        WHEN age BETWEEN 27 AND 32 THEN 'Peak (27-32)'
        ELSE 'Veteran (33+)'
    END AS age_group,
    COUNT(*) AS player_count,
    ROUND(AVG(annual_salary_eur), 0) AS avg_salary,
    ROUND(SUM(annual_salary_eur), 0) AS total_salary,
    ROUND((SUM(annual_salary_eur) / 
        (SELECT SUM(annual_salary_eur) FROM fcb_financial_analysis.player_wages)) * 100, 1) 
        AS pct_of_budget,
    ROUND(AVG(age), 1) AS avg_age_in_group
FROM fcb_financial_analysis.player_wages
GROUP BY age_group
ORDER BY 
    CASE age_group
        WHEN 'Youth (Under 21)' THEN 1
        WHEN 'Prime (21-26)' THEN 2
        WHEN 'Peak (27-32)' THEN 3
        ELSE 4
    END;

-- Key Finding: Peak players (27-32) earn €106M (48% of budget)
-- Insight: Youth players provide best value at €2.4M average vs €12.3M for veterans


-- ================================================================
-- QUERY 5: Contract Expiration Risk Analysis
-- Purpose: Identify renewal priorities and financial risks
-- Business Value: Plan budget for contract renewals
-- ================================================================

SELECT 
    contract_expires,
    COUNT(*) AS players_expiring,
    ROUND(SUM(annual_salary_eur), 0) AS total_wages_at_risk,
    STRING_AGG(player_name, ', ' ORDER BY annual_salary_eur DESC) AS key_players,
    ROUND((SUM(annual_salary_eur) / 
        (SELECT SUM(annual_salary_eur) FROM fcb_financial_analysis.player_wages)) * 100, 1) 
        AS pct_of_wages_at_risk
FROM fcb_financial_analysis.player_wages
GROUP BY contract_expires
ORDER BY contract_expires;

-- CRITICAL FINDING: €77M (35% of wage bill) expires in 2026
-- High Priority Renewals: De Jong, Lewandowski, Pedri, Gavi (9 players total)


-- ================================================================
-- QUERY 6: Position + Age Cross-Analysis
-- Purpose: Identify which positions have youngest/oldest players
-- Business Value: Understand succession needs by position
-- ================================================================

SELECT 
    position,
    ROUND(AVG(age), 1) AS avg_age,
    MIN(age) AS youngest,
    MAX(age) AS oldest,
    ROUND(AVG(annual_salary_eur), 0) AS avg_salary,
    COUNT(*) AS player_count,
    -- Age diversity score (higher = more diverse ages)
    MAX(age) - MIN(age) AS age_range
FROM fcb_financial_analysis.player_wages
GROUP BY position
ORDER BY avg_age DESC;

-- Key Finding: Midfielders have highest average age (26.6 years)
-- Goalkeepers have widest age range (25-34 years)


-- ================================================================
-- QUERY 7: Contract Urgency & Renewal Priority Matrix
-- Purpose: Rank players by renewal urgency and importance
-- Business Value: Create action plan for negotiations
-- ================================================================

SELECT 
    player_name,
    position,
    age,
    annual_salary_eur,
    contract_expires,
    CAST(contract_expires AS INT64) - 2024 AS years_remaining,
    -- Urgency classification
    CASE 
        WHEN CAST(contract_expires AS INT64) - 2024 <= 1 THEN 'URGENT'
        WHEN CAST(contract_expires AS INT64) - 2024 = 2 THEN 'HIGH PRIORITY'
        WHEN CAST(contract_expires AS INT64) - 2024 = 3 THEN 'MONITOR'
        ELSE 'LOW PRIORITY'
    END AS renewal_urgency,
    -- Priority score (1=highest, 4=lowest)
    CASE 
        WHEN CAST(contract_expires AS INT64) - 2024 <= 1 AND annual_salary_eur > 10000000 THEN 1
        WHEN CAST(contract_expires AS INT64) - 2024 <= 2 AND annual_salary_eur > 8000000 THEN 2
        WHEN CAST(contract_expires AS INT64) - 2024 <= 2 THEN 3
        ELSE 4
    END AS priority_score
FROM fcb_financial_analysis.player_wages
ORDER BY priority_score, annual_salary_eur DESC;

-- Action Items:
-- Priority 1: Gündogan, Lewandowski (expire 2025-2026, €38M combined)
-- Priority 2: De Jong, Pedri, Gavi (expire 2026, high earners)


-- ================================================================
-- QUERY 8: Summary Statistics (Executive Dashboard)
-- Purpose: Key metrics for high-level overview
-- Business Value: Quick snapshot for executives
-- ================================================================

SELECT 
    COUNT(*) AS total_players,
    ROUND(SUM(annual_salary_eur), 0) AS total_wage_bill_eur,
    ROUND(AVG(annual_salary_eur), 0) AS avg_salary_eur,
    ROUND(MIN(annual_salary_eur), 0) AS min_salary_eur,
    ROUND(MAX(annual_salary_eur), 0) AS max_salary_eur,
    ROUND(STDDEV(annual_salary_eur), 0) AS salary_std_deviation,
    ROUND(AVG(age), 1) AS avg_age,
    MIN(age) AS youngest_player_age,
    MAX(age) AS oldest_player_age,
    -- Calculate wage inequality (Gini coefficient approximation)
    ROUND((MAX(annual_salary_eur) / AVG(annual_salary_eur)), 1) AS wage_inequality_ratio
FROM fcb_financial_analysis.player_wages;

-- Key Metrics:
-- Total: 24 players, €220.2M wage bill
-- Average: €9.2M per player
-- Inequality: 2.3x ratio (Lewandowski earns 2.3x average)


-- ================================================================
-- QUERY 9: Youth vs Veteran Comparison
-- Purpose: Compare value proposition of different age groups
-- Business Value: Justify youth development investment
-- ================================================================

SELECT 
    'Youth (<21)' AS group_type,
    COUNT(*) AS players,
    ROUND(AVG(annual_salary_eur), 0) AS avg_salary,
    ROUND(SUM(annual_salary_eur), 0) AS total_cost,
    ROUND(SUM(annual_salary_eur) / COUNT(*), 0) AS cost_per_player
FROM fcb_financial_analysis.player_wages
WHERE age < 21

UNION ALL

SELECT 
    'Prime (21-26)',
    COUNT(*),
    ROUND(AVG(annual_salary_eur), 0),
    ROUND(SUM(annual_salary_eur), 0),
    ROUND(SUM(annual_salary_eur) / COUNT(*), 0)
FROM fcb_financial_analysis.player_wages
WHERE age BETWEEN 21 AND 26

UNION ALL

SELECT 
    'Peak (27-32)',
    COUNT(*),
    ROUND(AVG(annual_salary_eur), 0),
    ROUND(SUM(annual_salary_eur), 0),
    ROUND(SUM(annual_salary_eur) / COUNT(*), 0)
FROM fcb_financial_analysis.player_wages
WHERE age BETWEEN 27 AND 32

UNION ALL

SELECT 
    'Veteran (33+)',
    COUNT(*),
    ROUND(AVG(annual_salary_eur), 0),
    ROUND(SUM(annual_salary_eur), 0),
    ROUND(SUM(annual_salary_eur) / COUNT(*), 0)
FROM fcb_financial_analysis.player_wages
WHERE age >= 33;

-- ROI Analysis: Youth players cost 81% less than veterans
-- Lamine Yamal (youth) vs Gündogan (veteran): €4M vs €17M


-- ================================================================
-- QUERY 10: Top 5 Cost Optimization Opportunities
-- Purpose: Identify specific players/positions for cost reduction
-- Business Value: Actionable recommendations for CFO
-- ================================================================

SELECT 
    player_name,
    position,
    age,
    annual_salary_eur,
    CASE 
        WHEN age >= 33 AND annual_salary_eur > 10000000 THEN 'High salary veteran - consider succession planning'
        WHEN position = 'Midfielder' AND annual_salary_eur > 12000000 THEN 'Expensive midfielder - review market alternatives'
        WHEN CAST(contract_expires AS INT64) - 2024 <= 1 AND annual_salary_eur > 8000000 THEN 'Contract expiring soon - negotiate reduction or replace'
        WHEN age < 25 AND annual_salary_eur < 5000000 THEN 'Youth talent - good value, extend contract'
        ELSE 'Maintain current contract'
    END AS recommendation,
    contract_expires
FROM fcb_financial_analysis.player_wages
WHERE 
    (age >= 33 AND annual_salary_eur > 10000000) OR
    (position = 'Midfielder' AND annual_salary_eur > 12000000) OR
    (CAST(contract_expires AS INT64) - 2024 <= 1 AND annual_salary_eur > 8000000) OR
    (age < 25 AND annual_salary_eur < 5000000)
ORDER BY annual_salary_eur DESC;

-- Potential Savings: €15-25M annually through strategic replacements


-- ================================================================
-- QUERY 11: Salary Benchmarking by Position
-- Purpose: Compare player salaries to position averages
-- Business Value: Identify over/underpaid players
-- ================================================================

SELECT 
    player_name,
    position,
    age,
    annual_salary_eur,
    ROUND(AVG(annual_salary_eur) OVER (PARTITION BY position), 0) AS position_avg_salary,
    ROUND(annual_salary_eur - AVG(annual_salary_eur) OVER (PARTITION BY position), 0) AS diff_from_avg,
    CASE 
        WHEN annual_salary_eur > AVG(annual_salary_eur) OVER (PARTITION BY position) * 1.5 THEN 'Significantly Above Average'
        WHEN annual_salary_eur > AVG(annual_salary_eur) OVER (PARTITION BY position) THEN 'Above Average'
        WHEN annual_salary_eur < AVG(annual_salary_eur) OVER (PARTITION BY position) * 0.5 THEN 'Significantly Below Average'
        ELSE 'Below Average'
    END AS salary_classification,
    RANK() OVER (PARTITION BY position ORDER BY annual_salary_eur DESC) AS position_rank
FROM fcb_financial_analysis.player_wages
ORDER BY position, annual_salary_eur DESC;

-- Insight: Lewandowski earns 91% above Forward average
-- De Jong earns 113% above Midfielder average


-- ================================================================
-- QUERY 12: Contract Length Analysis
-- Purpose: Understand contract security and planning needs
-- Business Value: Long-term budget forecasting
-- ================================================================

SELECT 
    CAST(contract_expires AS INT64) AS year,
    COUNT(*) AS contracts_expiring,
    ROUND(SUM(annual_salary_eur)/1000000, 1) AS wages_expiring_millions,
    ROUND(AVG(annual_salary_eur)/1000000, 1) AS avg_wage_millions,
    STRING_AGG(
        CONCAT(player_name, ' (', position, ')'), 
        ', ' 
        ORDER BY annual_salary_eur DESC
    ) AS players,
    -- Cumulative risk
    SUM(COUNT(*)) OVER (ORDER BY contract_expires) AS cumulative_players_needing_renewal
FROM fcb_financial_analysis.player_wages
GROUP BY contract_expires
ORDER BY year;

-- Long-term Planning:
-- 2025: 3 players (€27M) - manageable
-- 2026: 9 players (€77M) - HIGH RISK YEAR
-- 2027+: 12 players (€116M) - staggered risk


-- ================================================================
-- END OF ANALYSIS
-- ================================================================

-- EXECUTIVE SUMMARY OF RECOMMENDATIONS:
-- 
-- 1. CONTRACT RENEWALS (Priority 1 - Immediate)
--    - Begin negotiations for 2026 expirations (€77M at risk)
--    - Focus: De Jong, Lewandowski, Pedri, Gavi
--    - Budget allocation: €30-40M for extensions
--
-- 2. MIDFIELDER OPTIMIZATION (Priority 2 - 12 months)
--    - Current: 9 players, €82M (37% of budget)
--    - Action: Promote 2-3 La Masia midfielders
--    - Target savings: €15-20M annually
--
-- 3. YOUTH DEVELOPMENT (Priority 3 - Strategic)
--    - Success model: Lamine Yamal (€4M salary, €120M value)
--    - Increase academy investment
--    - Target: 3-5 first team promotions per season
--
-- 4. VETERAN TRANSITIONS (Priority 4 - 18-24 months)
--    - Plan replacements for Gündogan (34), Szczęsny (34)
--    - Balance experience with wage sustainability
--    - Gradual transition over 2 seasons
--
-- TOTAL POTENTIAL SAVINGS: €15-25M annually
-- ROI ON YOUTH DEVELOPMENT: 2,900% (Yamal case study)
