CREATE DATABASE ENERGYDB2;
USE ENERGYDB2;

-- 1. country table
CREATE TABLE country(
    CID VARCHAR(10) PRIMARY KEY,
    Country VARCHAR(100) UNIQUE
);

SELECT * FROM COUNTRY;

-- 2. emission_3 table
CREATE TABLE emission_3 (
    country VARCHAR(100),
        energy_type VARCHAR(50),
    year INT,
    emission INT,
    per_capita_emission DOUBLE,
    FOREIGN KEY (country) REFERENCES country(Country)
);
SELECT * FROM EMISSION_3;


-- 3. population table
CREATE TABLE population (
    countries VARCHAR(100),
    year INT,
    Value DOUBLE,
    FOREIGN KEY (countries) REFERENCES country(Country)
);

SELECT * FROM POPULATION;

-- 4. production table
CREATE TABLE production (
    country VARCHAR(100),
    energy VARCHAR(50),
    year INT,
    production INT,
    FOREIGN KEY (country) REFERENCES country(Country)
);


SELECT * FROM PRODUCTION;

-- 5. gdp_3 table
CREATE TABLE gdp_3 (
    Country VARCHAR(100),
    year INT,
    Value DOUBLE,
    FOREIGN KEY (Country) REFERENCES country(Country)
);

SELECT * FROM GDP_3;

-- 6. consumption table
CREATE TABLE consumption (
    country VARCHAR(100),
    energy VARCHAR(50),
    year INT,
    consumption INT,
    FOREIGN KEY (country) REFERENCES country(Country)
);

SELECT * FROM CONSUMPTION;

-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Data Analysis Questions 

/* General & Comparative Analysis
What is the total emission per country for the most recent year available?
What are the top 5 countries by GDP in the most recent year?

Compare energy production and consumption by country and year. 

Which energy types contribute most to emissions across all countries?

*/

#1. What is the total emission per country for the most recent year available?

select country,year, 
		sum(emission) as Total_Emission from EMISSION_3 

		where year = (select max(year) from EMISSION_3) 

		group by country,year 

		order by Total_Emission desc;

--------------------------------------------------------------------------------------------------------------------------------------------------
#2. What are the top 5 countries by GDP in the most recent year?

select * 

	from  GDP_3  

	where year = (select max(year) from GDP_3) 

	order by value desc limit 5;


---------------------------------------------------------------------------------------------------------------------------------------------------
#3. Compare energy production and consumption by country and year.

select 
	P.country,P.year,P.TOTAL_PRODUCTION,C.TOTAL_CONSUMPTION,(P.TOTAL_PRODUCTION - C.TOTAL_CONSUMPTION) as difference 

	From (select country,year, sum(Production) as TOTAL_PRODUCTION from PRODUCTION group by country,year) as P join

	(select country,year, sum(Consumption) as TOTAL_CONSUMPTION from CONSUMPTION group by country,year) as C 

	on P.country = C. Country AND P.Year = C.Year order by P.Country,P.year;


----------------------------------------------------------------------------------------------------------------------------------------------------
#4. Which energy types contribute most to emissions across all countries?

select energy_type, 

	sum(emission) as Total_Emissions from EMISSION_3 

	group by energy_type 

	order by Total_Emissions desc limit 1 ;

-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 /* Trend Analysis Over Time
How have global emissions changed year over year?

What is the trend in GDP for each country over the given years?

How has population growth affected total emissions in each country?

Has energy consumption increased or decreased over the years for major economies?

What is the average yearly change in emissions per capita for each country?
*/

#1. How have global emissions changed year over year?

Select x.*,
		Lag(Total_EMS_Year) over (order by year asc) as Pre,

		round(((Total_EMS_Year - Lag(Total_EMS_Year) over (order by year asc))/
        
        Lag(Total_EMS_Year) over (order by year asc))*100,2) as YOY_EMS_Change

		from (select year, sum(emission) as Total_EMS_Year from EMISSION_3 group by year order by year ) x ;


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#2. What is the trend in GDP for each country over the given years?

with yearly as(                                                                                                            # creating temp table
			select country,year, sum(value) as Total_GDP from GDP_3 group by country,year                                            # creating table 
            )
            
			SELECT country,year,total_gdp,LAG(total_gdp) OVER (PARTITION BY country ORDER BY year) AS prev_year_gdp,                   # Finding previous values 

			round(((Total_gdp - LAG(total_gdp) OVER (PARTITION BY country ORDER BY year))/Nullif(LAG(total_gdp) 
            
            OVER (PARTITION BY country ORDER BY year),0))*100,2) as YOY_Trend           									 # Finding YOY Growth

			from yearly;
            

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#3. How has population growth affected total emissions in each country?

WITH country_year AS 

	(SELECT e.country,e.year,SUM(e.emission) AS total_emission,round(SUM(p.value),2) AS total_population

	FROM EMISSION_3 e JOIN POPULATION p ON e.country = p.countries AND e.year = p.year GROUP BY e.country, e.year),

with_growth AS 

	(SELECT country,year,total_emission,total_population, LAG(total_emission)  OVER (PARTITION BY country ORDER BY year) AS prev_emission,

	LAG(total_population) OVER (PARTITION BY country ORDER BY year) AS prev_population FROM country_year)

SELECT country,year,total_emission,total_population,

	ROUND((total_population - prev_population) * 100 / NULLIF(prev_population, 0),2) AS population_growth_pct,

	ROUND((total_emission - prev_emission) * 100 / NULLIF(prev_emission, 0),2) AS emission_growth_pct

	FROM with_growth

	WHERE prev_population IS NOT NULL

	ORDER BY country, year;


 ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 #4. Has energy consumption increased or decreased over the years for major economies?

WITH yearly AS 
	(SELECT country,year,SUM(consumption) AS Total_Consumption FROM CONSUMPTION GROUP BY country, year)

SELECT country,year,Total_Consumption,

	LAG(Total_Consumption) OVER (PARTITION BY country ORDER BY year) AS prev_year_consumption,

	(Total_Consumption - LAG(Total_Consumption) OVER (PARTITION BY country ORDER BY year)) AS change_from_prev_year,

CASE
	WHEN LAG(Total_Consumption) OVER (PARTITION BY country ORDER BY year) IS NULL THEN 'first_year'
    
	WHEN Total_Consumption > LAG(Total_Consumption) OVER (PARTITION BY country ORDER BY year) THEN 'increased'
    
	WHEN Total_Consumption < LAG(Total_Consumption) OVER (PARTITION BY country ORDER BY year) THEN 'decreased'
    
	ELSE 'no_change'
    
    END AS trend
    
FROM yearly

ORDER BY country, year;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------  
 #5.What is the average yearly change in emissions per capita for each country?  
  
SELECT country, 

	ROUND(AVG(YOY_Changes), 2) AS Average_YOY_Changes

	FROM (SELECT X.country,X.year,X.Total_Per_Capita,

	LAG(Total_Per_Capita) OVER (PARTITION BY country ORDER BY year) AS PRE_Capita,

	Total_Per_Capita - LAG(Total_Per_Capita) OVER (PARTITION BY country ORDER BY year) AS YOY_Changes

	FROM (SELECT country,year,SUM(per_capita_emission) AS Total_Per_Capita

	FROM EMISSION_3 GROUP BY country, year) AS X) AS T

	WHERE YOY_Changes IS NOT NULL

	GROUP BY country

	ORDER BY Average_YOY_Changes;


 

  
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------  
/* Ratio & Per Capita Analysis
What is the emission-to-GDP ratio for each country by year?

What is the energy consumption per capita for each country over the last decade?

How does energy production per capita vary across countries?

Which countries have the highest energy consumption relative to GDP?

What is the correlation between GDP growth and energy production growth?
*/

#1. What is the emission-to-GDP ratio for each country by year?

SELECT e.country,e.year,

	SUM(e.emission) AS total_emission,SUM(g.value) AS total_gdp,

	ROUND(SUM(e.emission) / NULLIF(SUM(g.value), 0), 6) AS emission_to_gdp_ratio

	FROM emission_3 e JOIN gdp_3 g ON e.country = g.country AND e.year = g.year 

	GROUP BY e.country, e.year ORDER BY e.country, e.year;


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
#2. What is the energy consumption per capita for each country over the last decade?

WITH last10 AS 

	(SELECT DISTINCT year FROM CONSUMPTION ORDER BY CAST(year AS UNSIGNED) DESC LIMIT 10)

SELECT c.country,c.year,

	SUM(c.consumption) AS total_consumption,round(SUM(p.value),2) AS total_population,

	ROUND(SUM(c.consumption) / NULLIF(SUM(p.value), 0), 6) AS consumption_per_capita

	FROM CONSUMPTION c JOIN POPULATION p ON c.country = p.countries

	AND c.year = p.year

	WHERE c.year IN (SELECT year FROM last10)

	GROUP BY c.country, c.year

	ORDER BY c.country, CAST(c.year AS UNSIGNED);

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#3. How does energy production per capita vary across countries?

SELECT p.country,p.year,

	ROUND(SUM(p.production) / SUM(pop.population), 4) AS Production_Per_Capita

	FROM PRODUCTION p JOIN POPULATION pop ON p.country = pop.country 

	AND p.year = pop.year WHERE p.year = (SELECT MAX(year) FROM PRODUCTION)

	GROUP BY p.country, p.year ORDER BY Production_Per_Capita DESC;



------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#4. Which countries have the highest energy consumption relative to GDP?

SELECT c.country,

	SUM(c.consumption) AS total_consumption,round(SUM(g.value),2) AS total_gdp,

	ROUND(SUM(c.consumption) / NULLIF(SUM(g.value), 0), 6) AS consumption_to_gdp_ratio

	FROM CONSUMPTION c JOIN GDP_3 g ON c.country = g.country AND c.year = g.year

	GROUP BY c.country ORDER BY consumption_to_gdp_ratio DESC LIMIT 5;

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#5. What is the correlation between GDP growth and energy production growth? ------------------------------------------------------------------------------------------------------------------------

WITH gdp_tot AS (
    SELECT country, year, SUM(value) AS gdp
    FROM GDP_3
    GROUP BY country, year
),
gdp_growth AS (
    SELECT 
        country,
        year,
        gdp,
        (gdp - LAG(gdp) OVER (PARTITION BY country ORDER BY year)) AS gdp_growth
    FROM gdp_tot
),
prod_tot AS (
    SELECT country, year, SUM(production) AS production
    FROM PRODUCTION
    GROUP BY country, year
),
prod_growth AS (
    SELECT 
        country,
        year,
        production,
        (production - LAG(production) OVER (PARTITION BY country ORDER BY year)) AS production_growth
    FROM prod_tot
),
combined AS (
    SELECT 
        g.country,
        g.year,
        g.gdp_growth,
        p.production_growth
    FROM gdp_growth g
    JOIN prod_growth p 
        ON g.country = p.country 
       AND g.year = p.year
    WHERE g.gdp_growth IS NOT NULL
      AND p.production_growth IS NOT NULL
),
stats AS (
    SELECT 
        country,
        AVG(gdp_growth) AS avg_gdp_growth,
        AVG(production_growth) AS avg_prod_growth
    FROM combined
    GROUP BY country
),
calc AS (
    SELECT 
        c.country,
        c.gdp_growth,
        c.production_growth,
        s.avg_gdp_growth,
        s.avg_prod_growth,
        (c.gdp_growth - s.avg_gdp_growth) AS x,
        (c.production_growth - s.avg_prod_growth) AS y
    FROM combined c
    JOIN stats s ON c.country = s.country
)
SELECT 
    country,
    SUM(x * y) /
    (SQRT(SUM(x*x)) * SQRT(SUM(y*y))) AS correlation
FROM calc
GROUP BY country;




-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* Global Comparisons

What are the top 10 countries by population and how do their emissions compare?

Which countries have improved (reduced) their per capita emissions the most over the last decade?

What is the global share (%) of emissions by country?

What is the global average GDP, emission, and population by year?
*/


#1. What are the top 10 countries by population and how do their emissions compare?

SELECT P.countries,P.Total_Population,E.Total_EMS

	FROM (SELECT countries, SUM(value) AS Total_Population FROM POPULATION GROUP BY countries) AS P JOIN 

	(SELECT country, SUM(emission) AS Total_EMS FROM EMISSION_3 GROUP BY country) AS E

	ON P.countries = E.country ORDER BY P.Total_Population DESC, E.Total_EMS DESC LIMIT 10;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#2. Which countries have improved (reduced) their per capita emissions the most over the last decade? 

select x.*, 
	lag(Total_Per_Capita) over (partition by country order by year) as PRE_Capita,
	round(((Total_Per_Capita - lag(Total_Per_Capita) over (partition by country order by year ) )/lag(Total_Per_Capita) over (partition by country order by year ))*100,2) as `YOY_Changes%`,
case
when round(((Total_Per_Capita - lag(Total_Per_Capita) over (partition by country order by year ) )/lag(Total_Per_Capita) over (partition by country order by year ))*100,2) >0 then "improved"
when round(((Total_Per_Capita - lag(Total_Per_Capita) over (partition by country order by year ) )/lag(Total_Per_Capita) over (partition by country order by year ))*100,2) =0 then "NO Changes"
when round(((Total_Per_Capita - lag(Total_Per_Capita) over (partition by country order by year ) )/lag(Total_Per_Capita) over (partition by country order by year ))*100,2) is null then "NO Value"
else "reduced"
end as Improvements_Status
from(select country,year, sum(per_capita_emission) as Total_Per_Capita from EMISSION_3 group by year,country order by year ) x ;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#3. What is the global share (%) of emissions by country?

SELECT country,

	ROUND( (SUM(emission) /(SELECT SUM(emission) FROM EMISSION_3)) * 100, 2 ) AS Share_Percent FROM EMISSION_3

	GROUP BY country ORDER BY Share_Percent DESC;


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#4. What is the global average GDP, emission, and population by year?

select G.Year,G.Average_GDP,E.Average_EMS,P.Average_POP 

	From (select year ,round(AVG(value),2) as Average_GDP from GDP_3 group by year) as G join

	(select year ,round(AVG(emission),2) as Average_EMS from EMISSION_3 group by year) as E on G.Year = E.year join

	(select year ,round(AVG(value),2) as Average_POP from POPULATION group by year) as P on G.Year= P.year order by G.year ;

-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------