-- Annual Revenue Trends by Commodity

-- Question: How has Oil and Gas revenue changed each year over 10 years?
-- This shows growth trends and which commodity drives revenue each year


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


-- Federal vs Native American Land Production

-- Question: How much oil and gas comes from government land vs tribal land?
-- This shows who benefits from production and how much money each gets

SELECT 
  -- Type of land ownership
  -- Federal = US government land (royalties go to Treasury)
  -- Native American = tribal land (royalties go to tribes)
  `Land Class`,
  
  -- Which product: Oil or Gas
  Commodity,
  
  -- Total amount produced
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
  AND `Land Class` IN ('Federal', 'Native American')
  AND Commodity IN ('Oil (bbl)', 'Gas (Mcf)')

GROUP BY `Land Class`, Commodity
ORDER BY revenue DESC;


-- Onshore vs Offshore Production

-- Question: Do we make more money from land drilling or ocean drilling?
-- This shows the split between onshore (land) and offshore (ocean) production

SELECT 
  -- Location type: Onshore (land) or Offshore (ocean)
  `Land Category`,
  
  -- Which product: Oil or Gas
  Commodity,
  
  -- Total amount produced
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
  AND `Land Category` IN ('Onshore', 'Offshore')
  AND Commodity IN ('Oil (bbl)', 'Gas (Mcf)')

GROUP BY `Land Category`, Commodity
ORDER BY revenue DESC;


-- Overall Business Summary (KPIs)

-- Question: What's our total business size across all years and locations?
-- This gives the "big picture" numbers for the entire dataset

SELECT 
  -- Total revenue from all oil and gas sales
  -- Oil: $50 per barrel, Gas: $3 per thousand cubic feet
  SUM(
    CASE 
      WHEN Commodity = 'Oil (bbl)' THEN Volume * 50
      WHEN Commodity = 'Gas (Mcf)' THEN Volume * 3
    END
  ) AS total_revenue,
  
  -- Total number of production transactions
  COUNT(*) AS total_transactions,
  
  -- How many different states we operate in
  COUNT(DISTINCT State) AS num_states,
  
  -- How many different counties we operate in
  COUNT(DISTINCT County) AS num_counties,
  
  -- First year in our data
  MIN(EXTRACT(YEAR FROM `Production Date`)) AS earliest_year,
  
  -- Most recent year in our data
  MAX(EXTRACT(YEAR FROM `Production Date`)) AS latest_year

FROM `us-oil-gas.oil_gas_production.production_data`

WHERE Volume > 0
  AND Commodity IN ('Oil (bbl)', 'Gas (Mcf)');


-- Seasonal Production Patterns (Quarterly Analysis)
-- Question: Which quarter (3-month period) has the highest production?
-- This shows if there are seasonal patterns we should plan for

SELECT 
  -- Quarter label with months for easier reading
  CASE EXTRACT(QUARTER FROM `Production Date`)
    WHEN 1 THEN 'Q1 (Jan-Mar)'
    WHEN 2 THEN 'Q2 (Apr-Jun)'
    WHEN 3 THEN 'Q3 (Jul-Sep)'
    WHEN 4 THEN 'Q4 (Oct-Dec)'
  END AS quarter_name,
  
  -- Which product: Oil or Gas
  Commodity,
  
  -- Average revenue per transaction in that quarter
  AVG(
    CASE 
      WHEN Commodity = 'Oil (bbl)' THEN Volume * 50
      WHEN Commodity = 'Gas (Mcf)' THEN Volume * 3
    END
  ) AS avg_revenue

FROM `us-oil-gas.oil_gas_production.production_data`

WHERE 
  Volume > 0
  AND `Production Date` IS NOT NULL
  AND Commodity IN ('Oil (bbl)', 'Gas (Mcf)')

GROUP BY quarter_name, Commodity
ORDER BY Commodity, quarter_name;

-- Top 15 Producing Counties

-- Question: Which specific counties generate the most revenue?
-- This shows our most important local production areas


SELECT 
  -- State abbreviation (e.g., NM, WY, TX)
  State,
  
  -- County name
  County,
  
  -- Which product: Oil or Gas
  Commodity,
  
  -- Total amount produced
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
  AND County IS NOT NULL
  AND Commodity IN ('Oil (bbl)', 'Gas (Mcf)')

GROUP BY State, County, Commodity
ORDER BY revenue DESC
LIMIT 15;


-- Top 10 Producing States

-- Question: Which states generate the most oil and gas revenue?
-- This shows our most important geographic markets

SELECT 
  -- State name (or "Offshore" for ocean production)
  COALESCE(State, 'Offshore') AS state_name,
  
  -- Which product: Oil or Gas
  Commodity,
  
  -- Total amount produced
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

GROUP BY state_name, Commodity
ORDER BY revenue DESC
LIMIT 10;



-- Production Disposition Analysis

-- Question: After we produce oil and gas, where does it go?
-- This shows whether production gets sold, stored, or used for operations

SELECT 
  -- What happened to the production
  -- Examples: "Sales" = sold to customers, "Inventory" = stored in tanks
  `Disposition Description`,
  
  -- Which product: Oil or Gas
  Commodity,
  
  -- Total volume for this disposition type
  SUM(Volume) AS total_volume,
  
  -- Number of transactions
  COUNT(*) AS transactions

FROM `us-oil-gas.oil_gas_production.production_data`

WHERE Volume > 0
  AND Commodity IN ('Oil (bbl)', 'Gas (Mcf)')

GROUP BY `Disposition Description`, Commodity
ORDER BY total_volume DESC
LIMIT 10;



-- Recent Revenue Trends (Last 5 Years)

-- Question: How has our total revenue changed in recent years?
-- This shows if we're growing or declining and helps forecast future revenue

SELECT 
  -- Get just the year from the date
  EXTRACT(YEAR FROM `Production Date`) AS year,
  
  -- Total revenue for that year (Oil + Gas combined)
  -- Oil: $50 per barrel
  -- Gas: $3 per thousand cubic feet
  SUM(
    CASE 
      WHEN Commodity = 'Oil (bbl)' THEN Volume * 50
      WHEN Commodity = 'Gas (Mcf)' THEN Volume * 3
    END
  ) AS annual_revenue,
  
  -- Number of transactions that year
  COUNT(*) AS transactions

FROM `us-oil-gas.oil_gas_production.production_data`

WHERE Volume > 0
  AND Commodity IN ('Oil (bbl)', 'Gas (Mcf)')
  AND EXTRACT(YEAR FROM `Production Date`) >= 2020  -- Last 5 years only

GROUP BY year
ORDER BY year DESC;



-- Oil vs Gas Portfolio Analysis

-- Question: Which commodity makes us more money - Oil or Gas?
-- This shows our complete business split between the two products

SELECT 
  -- Which product: Oil or Gas
  Commodity,
  
  -- Total amount produced (Oil in barrels, Gas in thousand cubic feet)
  SUM(Volume) AS total_volume,
  
  -- Total revenue in dollars
  -- We multiply by price to convert volume into money
  -- Oil sells for about $50 per barrel
  -- Gas sells for about $3 per thousand cubic feet
  SUM(
    CASE 
      WHEN Commodity = 'Oil (bbl)' THEN Volume * 50   -- Oil price
      WHEN Commodity = 'Gas (Mcf)' THEN Volume * 3    -- Gas price
    END
  ) AS revenue,
  
  -- How many sales transactions for each product
  COUNT(*) AS transactions

FROM `us-oil-gas.oil_gas_production.production_data`

-- Only include actual production (no negative adjustments)
WHERE Volume > 0
  AND Commodity IN ('Oil (bbl)', 'Gas (Mcf)')

-- Group by product type to get one row for Oil and one for Gas
GROUP BY Commodity;
