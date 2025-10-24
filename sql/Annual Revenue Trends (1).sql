-- Annual Revenue Trends by Commodity
-- ============================================================================
-- Question: How has Oil and Gas revenue changed each year over 10 years?
-- This shows growth trends and which commodity drives revenue each year
-- ============================================================================

SELECT 
  -- Extract the year from the production date
  EXTRACT(YEAR FROM `Production Date`) AS year,
  
  -- Which product: Oil or Gas
  Commodity,
  
  -- Total amount produced that year
  SUM(Volume) AS total_volume,
  
  -- Total revenue in dollars
  -- Oil: $50 per barrel
  -- Gas: $3 per thousand cubic feet
  SUM(
    CASE 
      WHEN Commodity = 'Oil (bbl)' THEN Volume * 50
      WHEN Commodity = 'Gas (Mcf)' THEN Volume * 3
    END
  ) AS revenue

FROM `us-oil-gas.oil_gas_production.production_data`

WHERE Volume > 0
  AND Commodity IN ('Oil (bbl)', 'Gas (Mcf)')

GROUP BY year, Commodity
ORDER BY year DESC;
--
-- BUSINESS IMPACT: We're becoming more oil-dependent. Oil went from 72%

-- of revenue (2015) to 79% (2024). Higher reward but higher risk.
