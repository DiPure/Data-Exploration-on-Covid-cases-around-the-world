/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covid_deaths
ORDER BY location, date
;

-- Looking at total cases vs total deaths by locations and date
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM covid_deaths
ORDER BY location, date
;

-- Shows likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM covid_deaths
WHERE location like '%Mexico%'
ORDER BY location, date
;

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid
SELECT location, date, total_cases, population, (total_cases/population)*100 AS cases_percentage
FROM covid_deaths
WHERE location like '%Mexico%'
ORDER BY location, date
;

-- Countries with Highest Infection Rate compared to Population (using subquery)
SELECT location, total_cases, population, (total_cases/population)*100 AS cases_percentage
FROM (
	SELECT  location,
			MAX(total_cases) AS total_cases, 
			population
	FROM covid_deaths
	GROUP BY location, population
	ORDER BY location
	) AS f_table
WHERE (total_cases/population)*100 IS NOT NULL
ORDER BY cases_percentage DESC
;

-- Countries with Highest Infection Rate compared to Population.
SELECT  location,
		MAX(total_cases) AS total_cases, 
		population,
		MAX(total_cases/population)*100 AS cases_percentage
FROM covid_deaths
GROUP BY location, population
HAVING MAX(total_cases/population) IS NOT NULL
ORDER BY cases_percentage DESC
;

-- Countries with Highest Death Count per Population
SELECT  location, 
		population, 
		MAX(CAST(total_deaths AS int)) AS total_death_count
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY location, population
HAVING MAX(total_deaths) IS NOT NULL
ORDER BY total_death_count DESC
;

-- Continents with Highest Death Count per Population
SELECT  location,
		MAX(total_deaths) AS total_deaths_count
FROM covid_deaths
WHERE continent IS NULL
GROUP BY location
ORDER BY total_deaths_count DESC
;

-- Global numbers
SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(new_cases)*100 AS death_percentage
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date
;

SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(new_cases)*100 AS death_percentage
FROM covid_deaths
WHERE continent IS NOT NULL
;



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
SELECT  dea.continent,
		dea.location,
		dea.date,
		dea.population,
		vac.new_vaccinations,
		SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_people_vaccinated
FROM covid_deaths AS dea
	JOIN covid_vaccinations AS vac
		ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date
;

-- Using CTE to perform Calculation on Partition By in the previous query
WITH PopvsVac (Continent, Location, Date, Population, New_vacinations, Rolling_people_vaccinated)
AS
(
	SELECT  dea.continent,
		dea.location,
		dea.date,
		dea.population,
		vac.new_vaccinations,
		SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_people_vaccinated
	FROM covid_deaths AS dea
		JOIN covid_vaccinations AS vac
			ON dea.location = vac.location AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	ORDER BY dea.location, dea.date
)
SELECT *, (Rolling_people_vaccinated/Population)*100 AS People_vaccinated_percentage
FROM PopvsVac
;

-- Same exercise but using subquery
SELECT *, (Rolling_people_vaccinated/Population)*100
FROM
(
	SELECT  dea.continent,
		dea.location,
		dea.date,
		dea.population,
		vac.new_vaccinations,
		SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_people_vaccinated
	FROM covid_deaths AS dea
		JOIN covid_vaccinations AS vac
			ON dea.location = vac.location AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	ORDER BY dea.location, dea.date
) AS nested
--WHERE location = 'Albania'
;


-- Using Temp Table to perform Calculation on Partition By in the previous query
DROP TABLE IF EXISTS Percent_Population_Vaccinated;
CREATE TABLE Percent_Population_Vaccinated
(
Continent varchar(255),
Location varchar(255),
Date date,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
);

INSERT INTO Percent_Population_Vaccinated
SELECT  dea.continent,
		dea.location,
		dea.date,
		dea.population,
		vac.new_vaccinations,
		SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_people_vaccinated
FROM covid_deaths AS dea
	JOIN covid_vaccinations AS vac
		ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date
;

Select *, (RollingPeopleVaccinated/Population)*100 AS Population_vaccinated_percentage
FROM Percent_Population_Vaccinated
;