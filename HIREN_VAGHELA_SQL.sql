CREATE DATABASE AQI;
Use AQI;

CREATE TABLE aqi_raw (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    City          VARCHAR(100),
    Date          VARCHAR(20),          -- Keep as string to preserve raw format
    PM2_5         VARCHAR(20),          -- Use VARCHAR to catch bad entries
    PM10          VARCHAR(20),
    NO            VARCHAR(20),
    NO2           VARCHAR(20),
    NOx           VARCHAR(20),
    NH3           VARCHAR(20),
    CO            VARCHAR(20),
    SO2           VARCHAR(20),
    O3            VARCHAR(20),
    Benzene       VARCHAR(20),
    Toluene       VARCHAR(20),
    Xylene        VARCHAR(20),
    AQI           VARCHAR(20),
    AQI_Bucket    VARCHAR(50)
);

select count(*) from aqi_raw;
Select * from aqi_raw;
describe aqi_raw;

--  

SET SQL_SAFE_UPDATES = 0;

UPDATE aqi_raw
SET 
    PM2_5 = NULLIF(TRIM(PM2_5), ''),
    PM10  = NULLIF(TRIM(PM10), ''),
    NO    = NULLIF(TRIM(NO), ''),
    NO2   = NULLIF(TRIM(NO2), ''),
    NOx   = NULLIF(TRIM(NOx), ''),
    NH3   = NULLIF(TRIM(NH3), ''),
    CO    = NULLIF(TRIM(CO), ''),
    SO2   = NULLIF(TRIM(SO2), ''),
    O3    = NULLIF(TRIM(O3), ''),
    Benzene = NULLIF(TRIM(Benzene), ''),
    Toluene = NULLIF(TRIM(Toluene), ''),
    Xylene  = NULLIF(TRIM(Xylene), ''),
    AQI     = NULLIF(TRIM(AQI), ''),
    AQI_Bucket = NULLIF(TRIM(AQI_Bucket),'');
    
update aqi_raw SET AQI_Bucket = NULLIF(TRIM(AQI_Bucket),'')
    


ALTER TABLE aqi_raw
MODIFY Date Date,
MODIFY PM2_5   DECIMAL(10,2),
MODIFY PM10    DECIMAL(10,2),
MODIFY NO      DECIMAL(10,2),
MODIFY NO2     DECIMAL(10,2),
MODIFY NOx     DECIMAL(10,2),
MODIFY NH3     DECIMAL(10,2),
MODIFY CO      DECIMAL(10,2),
MODIFY SO2     DECIMAL(10,2),
MODIFY O3      DECIMAL(10,2),
MODIFY Benzene DECIMAL(10,2),
MODIFY Toluene DECIMAL(10,2),
MODIFY Xylene  DECIMAL(10,2),
MODIFY AQI     DECIMAL(10,2);

describe aqi_raw;

Select * from aqi_raw;

-- Query For the Check Duplicate Rows 

Select city , date , count(*) as total_count
from aqi_raw
group by city , date
having total_count > 1;

CREATE TABLE aqi_cleaned (
    id INT,
    City VARCHAR(50),
    Date DATE,
    PM2_5 DECIMAL(10,2),
    PM10 DECIMAL(10,2),
    NO DECIMAL(10,2),
    NO2 DECIMAL(10,2),
    NOx DECIMAL(10,2),
    NH3 DECIMAL(10,2),
    CO DECIMAL(10,2),
    SO2 DECIMAL(10,2),
    O3 DECIMAL(10,2),
    Benzene DECIMAL(10,2),
    Toluene DECIMAL(10,2),
    Xylene  DECIMAL(10,2),
    AQI DECIMAL(10,2),
    AQI_Bucket VARCHAR(20),
    Month INT,
    Year INT,
    Monthly_AQI DECIMAL(10,2),
    PM_Ratio DECIMAL(10,4),
    NO2_NOx_Ratio DECIMAL(10,4),
    CO_O3_Ratio DECIMAL(10,4),
    SO2_NO2_Ratio DECIMAL(10,4)
);
ALTER TABLE aqi_cleaned
MODIFY Date Date;

SET SQL_SAFE_UPDATES = 0;

UPDATE aqi_cleaned
SET 
    PM_Ratio = ROUND(PM_Ratio, 4),
    NO2_NOx_Ratio = ROUND(NO2_NOx_Ratio, 4),
    CO_O3_Ratio = ROUND(CO_O3_Ratio, 4),
    SO2_NO2_Ratio = ROUND(SO2_NO2_Ratio, 4);

select * from aqi_cleaned;


-- Problem Statement 5: Advanced SQL Analytics on Cleaned Data

-- SELECT 
--     a.City,a.Date,a.AQI,a.Month,a.Year,round(m.Monthly_AQI,2)
-- FROM aqi_cleaned a
-- JOIN (
--     SELECT 
--         City,
--         Year,
--         Month,
--         AVG(AQI) AS Monthly_AQI
--     FROM aqi_cleaned
--     GROUP BY City, Year, Month
-- ) m
-- ON a.City = m.City 
-- AND a.Year = m.Year 
-- AND a.Month = m.Month;

SELECT City,Year,Month,ROUND(AVG(AQI),2) AS Monthly_AQI
FROM aqi_cleaned
GROUP BY City, Year, Month;


-- Identify cities with AQI above national average 


SELECT City, ROUND(AVG(AQI),2) AS Avg_AQI
FROM aqi_cleaned
GROUP BY City
HAVING Avg_AQI > (
    SELECT AVG(AQI) FROM aqi_cleaned
)
order by Avg_AQI DESC; 


--  Rank cities by AQI within each year

SELECT 
    City,
    YEAR(Date) AS Year,
    ROUND(AVG(AQI),2) AS Avg_AQI,
    RANK() OVER (PARTITION BY YEAR(Date) ORDER BY ROUND(AVG(AQI),2) DESC) AS Rank_in_Year
FROM aqi_cleaned
GROUP BY City, YEAR(Date);


-- 	Compute moving average AQI per city

SELECT City,Date,AQI,
AVG(AQI) OVER (
        PARTITION BY City
        ORDER BY Date
    ) AS Moving_Avg_AQI
FROM aqi_cleaned;

-- Maintain summary tables

CREATE TABLE IF NOT EXISTS aqi_city_summary (
    City           VARCHAR(100) PRIMARY KEY,
    Avg_AQI        FLOAT,
    Max_AQI        FLOAT,
    Min_AQI        FLOAT,
    Dominant_Bucket VARCHAR(50),
    Total_Days     INT
);

INSERT INTO aqi_city_summary
SELECT
    City,
    ROUND(AVG(AQI), 2),
    MAX(AQI),
    MIN(AQI),
    -- Most frequent AQI bucket
    (SELECT AQI_Bucket
     FROM aqi_cleaned c2
     WHERE c2.City = c1.City AND AQI_Bucket IS NOT NULL
     GROUP BY AQI_Bucket ORDER BY COUNT(*) DESC LIMIT 1),
    COUNT(DISTINCT Date)
FROM aqi_cleaned c1
GROUP BY City;

Select * from aqi_city_summary;

CREATE TABLE city_aqi_summary AS
SELECT 
    City,
    AVG(AQI) AS avg_aqi,
    MAX(AQI) AS max_aqi,
    MIN(AQI) AS min_aqi,
    COUNT(*) AS total_records
FROM aqi_cleaned
GROUP BY City;

Select * from city_aqi_summary;

