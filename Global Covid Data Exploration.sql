SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

--SELECT *
--FROM PortfolioProject..CovidVacinations
--ORDER BY 3,4

-- Select Data that we are going to be using

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2


-- Looking at total cases vs deaths in all conrties and days up to 23/02/2023

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS Death_Percentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2


-- Looking at total cases vs deaths in South Africa up to 23/02/2023
-- Shows likelihood of you dying if you contract covid in South Africa

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS Death_Percentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'South Africa' AND continent IS NOT NULL
ORDER BY 1,2

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS Death_Percentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2


-- Looking at total_cases vs population
-- Shows what percentage of population got Covid

SELECT Location, date, population, total_cases, (total_cases/population) * 100 AS Percent_Population_Invected
FROM PortfolioProject..CovidDeaths
WHERE location = 'South Africa'
ORDER BY 1,2

SELECT Location, date, population, total_cases, (total_cases/population) * 100 AS Percent_Population_Invected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2


-- Which Contry has the highest invection rate compared to population

SELECT Location, population, MAX(total_cases) AS Highest_Invection_Count, MAX((total_cases/population)) * 100 AS Percent_Population_Invected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY Percent_Population_Invected DESC


-- Contries with the highest death count per population

SELECT location, MAX(CAST(total_deaths AS bigint)) AS Total_Death_Count
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY Total_Death_Count DESC


-- Let's break things down by Continent
-- Showing continents with the highest death counts per population

SELECT continent, MAX(CAST(total_deaths AS bigint)) AS Total_Death_Count
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND location NOT IN ('High Income', 'Upper middle income', 'Lower middle income', 'Low income', 'International', 'World')
GROUP BY continent
ORDER BY Total_Death_Count DESC

--SELECT location, MAX(CAST(total_deaths AS bigint)) AS Total_Death_Count
--FROM PortfolioProject..CovidDeaths
--WHERE continent IS NULL AND location NOT IN ('High Income', 'Upper middle income', 'Lower middle income', 'Low income', 'International')
--GROUP BY location
--ORDER BY Total_Death_Count DESC


-- Global Numbers

SELECT date, SUM(new_cases) AS Global_Total_Cases, SUM(CAST(new_deaths AS bigint)) AS Global_Total_Deaths, SUM(CAST(new_deaths AS bigint))/SUM(new_cases) * 100 AS Death_Percentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

-- Global Totals
SELECT SUM(new_cases) AS Global_Total_Cases, SUM(CAST(new_deaths AS bigint)) AS Global_Total_Deaths, SUM(CAST(new_deaths AS bigint))/SUM(new_cases) * 100 AS Death_Percentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2


-- Vaccinations

SELECT *
FROM PortfolioProject..CovidVacinations


-- Joining Covid Deaths and Covid Vaccinations tables

SELECT *
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVacinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date


-- Looking at Total Population vs Vaccinations

-- Using CTE

WITH popvsvac (continent, location, date, population, new_vaccinations, Rolling_People_Vaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVacinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (Rolling_People_Vaccinated/population) * 100 AS Population_Percent_Vaccinated
FROM popvsvac


-- Using a Temp Table
DROP TABLE IF EXISTS #Percent_Population_Vaccinated
CREATE TABLE #Percent_Population_Vaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
Rolling_People_Vaccinated numeric
)
INSERT INTO #Percent_Population_Vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVacinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (Rolling_People_Vaccinated/population) * 100 AS Population_Percent_Vaccinated
FROM #Percent_Population_Vaccinated


-- Creating View to store data for later data visualizations
USE PortfolioProject
GO
CREATE VIEW Percent_Population_Vaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVacinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

USE PortfolioProject
GO
CREATE VIEW casesVSdeaths AS
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS Death_Percentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL

USE PortfolioProject
GO
CREATE VIEW casesVSpopulation AS
SELECT Location, date, population, total_cases, (total_cases/population) * 100 AS Percent_Population_Invected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL

USE PortfolioProject
GO
CREATE VIEW invected_population AS
SELECT Location, population, MAX(total_cases) AS Highest_Invection_Count, MAX((total_cases/population)) * 100 AS Percent_Population_Invected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population

USE PortfolioProject
GO
CREATE VIEW highest_deaths AS
SELECT location, MAX(CAST(total_deaths AS bigint)) AS Total_Death_Count
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location


USE PortfolioProject
GO
CREATE VIEW highest_deaths_continent AS
SELECT continent, MAX(CAST(total_deaths AS bigint)) AS Total_Death_Count
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND location NOT IN ('High Income', 'Upper middle income', 'Lower middle income', 'Low income', 'International', 'World')
GROUP BY continent
