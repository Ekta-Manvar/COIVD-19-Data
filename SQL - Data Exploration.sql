 
/****** CoivdData from Feb 24, 2020 to Jan 25, 2022  ******/


--Created View because dont want to use where condition in each SQL statement
DROP VIEW IF exists V_CovidDeaths 
GO

CREATE VIEW V_CovidDeaths AS
SELECT *
FROM portfolio.dbo.CovidDeaths
WHERE continent is not null
GO


  -- Looking at total deaths vs total cases
  -- Shows chances of dying if you contract with covid in your country
  SELECT DISTINCT location FROM  V_CovidDeaths ORDER BY location  /* To see location name */

  SELECT location, date, total_cases, total_deaths, CONCAT(ROUND((total_deaths/total_cases)*100,2), '%') AS DeathPercentage
  FROM  V_CovidDeaths
  WHERE location='Canada'
  ORDER BY date DESC


  -- Looking at total cases vs total population
  -- What percentage of population got covid in your country
  SELECT location, date, total_cases, population, CONCAT(ROUND((total_cases/population)*100,2), '%') AS CovidPercentage
  FROM  V_CovidDeaths
  WHERE location='Canada'
  ORDER BY date DESC


  --Countries with highest covid cases over the population
  SELECT location, population, MAX(total_cases) AS CovidCases, 
  MAX(ROUND((total_cases/population)*100, 2)) AS CovidPercentage
  FROM  V_CovidDeaths
  GROUP BY location, population
  ORDER BY CovidPercentage DESC


  -- Countries with highest death count per popultion
  SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalCovidDeaths /* converted datetype from nvarchar(255) to float */
  FROM  V_CovidDeaths
  GROUP BY location
  ORDER BY TotalCovidDeaths desc


  -- How many people are alive who contract with covid
  SELECT location, MAX(total_cases) AS TotalCases, MAX(total_cases)- MAX(total_deaths) AS TotalAlive
  FROM V_CovidDeaths
  GROUP BY location
  ORDER BY TotalAlive DESC


  -- Country with highest coivd cases, lowest covid cases, no covid cases
  SELECT TOP 1 location, MAX(total_cases) AS HighestCovidCases
  FROM V_CovidDeaths
  GROUP BY location
  ORDER BY HighestCovidCases DESC

  SELECT  TOP 2 location, MAX(total_cases) AS LowestCovidCases /* Top 2 because two countires have same cases*/
  FROM V_CovidDeaths
  GROUP BY location
  HAVING MAX(total_cases) is not null  /* filters countries with covid cases only */
  ORDER BY LowestCovidCases    

  SELECT location, ISNULL(MAX(total_cases), 0) AS TotalCases /* Replace Null value with zero */
  FROM V_CovidDeaths
  GROUP BY location
  HAVING MAX(total_cases) is null  /* filters countries with no covid cases - Null means no coivd cases*/
  ORDER BY location 


 -- How many patients admitted in the hospital because of covid 
 SELECT location, SUM(CAST(hosp_patients AS BIGINT)) AS AdmittedInHospital /* converted datatype from nvarchar(255)  into int */
 FROM V_CovidDeaths
 GROUP BY location
 ORDER BY AdmittedInHospital DESC
 

 -- Total number of covid cases for each location in the year 2020, 2021, 2022
 --1st Way (CTE)
 WITH Max_Cases AS
   (
      SELECT location, YEAR(date) AS Year, total_cases
      FROM V_CovidDeaths
   ) 
   SELECT  * FROM Max_Cases
   PIVOT
   (
      MAX(total_cases) FOR Year IN([2020], [2021], [2022])
   ) 
   AS pivottable

ORDER BY location

-- Second Way (Derived table)
 SELECT * FROM
   (
      SELECT location, YEAR(date) AS Year, total_cases
      FROM V_CovidDeaths
   ) 
   AS totalcases
   PIVOT
   (
      MAX(total_cases) FOR Year IN([2020], [2021], [2022])
   ) 
   AS pivottable

ORDER BY location


  -- Total covid cases and total deaths all over the world
  --1st way (Derived table)
 SELECT SUM(TotalCases) AS WorldWide_Cases, SUM(TotalDeaths) AS WorldWide_Deaths, 
  ROUND(SUM(TotalDeaths)/SUM(TotalCases)*100, 2) AS WorldWide_DeathPercentage 
  FROM
 (
 SELECT MAX(total_cases) AS TotalCases, MAX(total_deaths) AS TotalDeaths
  FROM V_CovidDeaths
  GROUP BY continent
  )  AS total
  

  -- 2nd way (CTE)
  WITH WorldWideCases AS
  (
  SELECT continent, MAX(total_cases) AS TotalCases, MAX(total_deaths) AS TotalDeaths
  FROM V_CovidDeaths
  GROUP BY continent
  )
  SELECT SUM(TotalCases), SUM(TotalDeaths)
  FROM WorldWideCases


  -- Total Vaccination
  SELECT d.location, MAX(CAST(v.total_vaccinations AS BIGINT)) AS TotalVaccinations  
  FROM portfolio.dbo.CovidDeaths d
  JOIN portfolio.dbo.CovidVaccinations v
  ON d.date=v.date and d.location=v.location
  WHERE d.continent is not null /* Joined tables based on common columns*/
  GROUP BY d.location
  ORDER BY d.location


  ---Final table will use for tableau visualizations
  
  -- Changing datatypes of  few columns to correct ones
  
  ALTER TABLE portfolio.dbo.CovidDeaths
  ALTER COLUMN hosp_patients BIGINT

  ALTER TABLE portfolio.dbo.CovidDeaths
  ALTER COLUMN icu_patients BIGINT

  ALTER TABLE portfolio.dbo.CovidVaccinations
  ALTER COLUMN total_vaccinations BIGINT

  ALTER TABLE portfolio.dbo.CovidVaccinations
  ALTER COLUMN people_vaccinated BIGINT

  ALTER TABLE portfolio.dbo.CovidVaccinations
  ALTER COLUMN people_fully_vaccinated BIGINT

  ALTER TABLE portfolio.dbo.CovidVaccinations
  ALTER COLUMN total_boosters BIGINT


  -- selected required data for visualization - Used in tableau custom SQL query after connecting with database 

  -- selected required data for visualization - Used in tableau custom SQL after connecting with database 
SELECT d.continent AS Continent, 
          CASE d.location 
		    WHEN 'United States' THEN 'US'
			WHEN 'United Kingdom' THEN 'UK'
			ELSE d.location
		   END
		   AS Country, 
         d.date AS Date, d.population AS Population, 
         ISNULL(d.new_cases,0) AS New_Cases, 
         ISNULL(d.new_deaths, 0) AS New_Deaths,  
         ISNULL(d.hosp_patients,0) AS Hospitalized, 
         ISNULL(d.icu_patients,0) AS ICU_Patients, 
         ISNULL(v.total_vaccinations,0) AS Total_Vaccinations, 
         ISNULL(v.people_vaccinated,0) AS People_Vaccinated, 
	     ISNULL(v.people_fully_vaccinated,0) AS People_Fully_Vaccinated, 
         ISNULL(v.total_boosters,0) AS Total_Boosters
  FROM portfolio.dbo.CovidDeaths d
  JOIN portfolio.dbo.CovidVaccinations v
  ON d.date=v.date and d.location=v.location
  WHERE d.continent is not null 
  ORDER BY d.location





  
