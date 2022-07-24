-- If this table already exists, Destroy it--
Drop VIEW
IF EXISTS forestation;
---------------------------------------------

--Create Forestion TABLE--
CREATE VIEW forestation AS
SELECT for_a.country_code code, for_a.country_name country, 
  for_a.year "year", for_a.forest_area_sqkm forest_area_sqkm,
  lan_a.total_area_sq_mi total_area_sq_mi, 
  regi.region region, regi.income_group income_group,
  100.0*(for_a.forest_area_sqkm / 
  (lan_a.total_area_sq_mi * 2.59)) AS percentage
FROM forest_area for_a, land_area lan_a, regions regi
WHERE (for_a.country_code  = lan_a.country_code AND
  for_a.year = lan_a.year AND
  regi.country_code = lan_a.country_code);
---------------------------

   
--Show Forestation Table--
SELECT *
   FROM forestation;
---------------------------


--1. GLOBAL SITUATION

--Total Area Square km (1990)--
SELECT SUM(forest_area_sqkm)
   FROM forestation
   WHERE year = 1990
   AND REGION = 'World';
--------------------------------- 

--Total Area Square km (2016)--
SELECT SUM(forest_area_sqkm)
   FROM forestation
   WHERE year = 2016
   AND REGION = 'World'; 
----------------------------------
   
--Difference between 1990 and 2016)--
SELECT now.forest_area_sqkm - b4.forest_area_sqkm
AS diff
FROM forestation AS now
JOIN forestation AS b4
ON (now.country = 'World' AND b4.country = 'World' AND now.year = '2016' AND b4.year = '1990');
------------------------------------------
   
--Percent change between 1990 and 2016)--
SELECT (now.forest_area_sqkm - b4.forest_area_sqkm) / b4.forest_area_sqkm * 100
AS Percentage
FROM forestation AS now
JOIN forestation AS b4
ON (now.country = 'World' AND b4.country = 'World' AND now.year = '2016' AND b4.year = '1990');
------------------------------------------

-- Forest area "metric conversion" (2016)--
SELECT country, (total_area_sq_mi * 2.59) AS total_area_sqkm
FROM forestation
WHERE year = 2016
ORDER BY total_area_sqkm;
-------------------------------------------


-- 2. REGIONAL OUTLOOK


   
--World Percentage (2016)--   
   SELECT percentage
   FROM forestation
   WHERE year = 2016
   AND country = 'World';
---------------------------
   
--World Percentage (1990)--   
   SELECT percentage
   FROM forestation
   WHERE year = 1990
   AND country = 'World';
---------------------------
--Percentage Then -- Now -- And Region ------
SELECT ROUND(CAST((region_forest_1990/ region_area_1990) * 100 AS NUMERIC),
2)
AS forest_percent_1990,
ROUND(CAST((region_forest_2016 / region_area_2016) * 100 AS NUMERIC), 2)
AS forest_percent_2016,
region
FROM (SELECT SUM(Table_a.forest_area_sqkm) region_forest_1990,
SUM(Table_a.total_area_sq_mi * 2.59) region_area_1990, Table_a.region,
SUM(Table_b.forest_area_sqkm) region_forest_2016,
SUM(Table_b.total_area_sq_mi * 2.59) region_area_2016
FROM forestation Table_a, forestation Table_b
WHERE Table_a.year = '1990'
AND Table_a.country != 'World'
AND Table_b.year = '2016'
AND Table_b.country != 'World'
AND Table_a.region = Table_b.region
GROUP BY Table_a.region) Regional_percentage
ORDER BY forest_percent_1990 DESC;  
--Countries with Difference in forestation between now and then--
SELECT current.country_name, 
  current.forest_area_sqkm - b4.forest_area_sqkm AS difference
FROM forest_area AS current
JOIN forest_area AS b4
  ON  (current.year = '2016' AND b4.year = '1990')
  AND current.country_name = b4.country_name
ORDER BY difference DESC;
-----------------------------------------------------------------


-- 3. COUNTRY-LEVEL DETAIL--


------ 3-A.	SUCCESS STORIES --

--Countries with Percentage growth in forestation between now and then--
SELECT current.country_name, 
  ROUND(CAST((current.forest_area_sqkm - b4.forest_area_sqkm) / b4.forest_area_sqkm * 100 AS NUMERIC), 2) AS Growth 
FROM forest_area AS current
JOIN forest_area AS b4
  ON  (current.year = '2016' AND b4.year = '1990')
  AND current.country_name = b4.country_name
ORDER BY Growth DESC;
-----------------------------------------------------------------



--Countries with Difference in forestation between now and then--
SELECT current.country_name, 
  current.forest_area_sqkm - b4.forest_area_sqkm AS difference
FROM forest_area AS current
JOIN forest_area AS b4
  ON  (current.year = '2016' AND b4.year = '1990')
  AND current.country_name = b4.country_name
ORDER BY difference DESC;
-----------------------------------------------------------------

---- 3-B.	LARGEST CONCERNS --

--Countries with Difference in Absolute forest change between now and then--

SELECT current.country, 
current.region,
current.forest_area_sqkm - b4.forest_area_sqkm AS difference
FROM forestation AS current
JOIN forestation AS b4
  ON  (current.year = '2016' AND b4.year = '1990')
  AND current.country = b4.country
  WHERE current.forest_area_sqkm IS NOT NULL
  AND b4.forest_area_sqkm IS NOT NULL
  AND b4.country != 'World'
  AND current.country != 'World'
ORDER BY difference
Limit 5;
-----------------------------------------------------

--Countries with Difference in Percent forest change between now and then--
SELECT current.country, 
current.region,
ROUND(CAST((current.forest_area_sqkm - b4.forest_area_sqkm) / b4.forest_area_sqkm * 100 AS NUMERIC), 2) AS Percentage
FROM forestation AS current
JOIN forestation AS b4
  ON  (current.year = '2016' AND b4.year = '1990')
  AND current.country = b4.country
  WHERE current.forest_area_sqkm IS NOT NULL
  AND b4.forest_area_sqkm IS NOT NULL
  AND b4.country != 'World'
  AND current.country != 'World'
ORDER BY Percentage
LIMIT 5;
-------------------------------------------

--- 3-C.	QUARTILES --

-- Countries Grouped by Forestation Percent Quartiles----
SELECT DISTINCT(Quartiles), COUNT(Country) OVER (PARTITION BY Quartiles) AS Number_of_Countries
FROM (SELECT country,
      CASE WHEN percentage >= 0 AND percentage <= 25 THEN '0% - 25%' 
      WHEN percentage > 25 AND percentage <= 50 THEN '25% - 50%' 
      WHEN percentage > 50 AND percentage <= 75 THEN '50% - 75%' 
      WHEN percentage > 75 AND percentage <= 100 THEN '75% - 100%' 
      ELSE 'INVALID'
      END AS Quartiles FROM forestation
      WHERE Percentage IS NOT NULL AND year = 2016) quart;

-- 3.4 Top Quartile Countries ---
SELECT country, Region, Percentage
FROM forestation
WHERE year = 2016 AND Percentage > 75
ORDER BY percentage DESC;

-----------------------------------------------------------------