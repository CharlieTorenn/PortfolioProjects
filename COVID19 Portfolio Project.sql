--select * FROM [Portfolio Project1]..CovidDeaths
--order by 3,4

--select * FROM [Portfolio Project1]..CovidVaccinations
--order by 3,4

--Select Data that will be used

SELECT Location, date, total_cases, new_cases, total_deaths, population 
FROM [Portfolio Project1]..CovidDeaths
ORDER BY 1,2

--Change data type for division

ALTER TABLE [Portfolio Project1]..CovidDeaths ALTER COLUMN total_deaths float
ALTER TABLE [Portfolio Project1]..CovidDeaths ALTER COLUMN total_cases float
ALTER TABLE [Portfolio Project1]..CovidDeaths ALTER COLUMN total_cases_per_million float
ALTER TABLE [Portfolio Project1]..CovidDeaths ALTER COLUMN total_deaths_per_million float 

--Looking at Total Cases vs Total Deaths 
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage 
FROM [Portfolio Project1]..CovidDeaths
ORDER BY 1,2

--Change data type in CovidVaccinations
ALTER TABLE [Portfolio Project1]..CovidVaccinations ALTER COLUMN total_tests float
 
 -- Considering Total Cases vs Total Deaths in United States
 --Shows the liklihood of dying if you contract COVID in the United States over Time
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage 
FROM [Portfolio Project1]..CovidDeaths where Location='United States'
ORDER BY 1,2

SELECT Location, date, Population, total_cases, (total_cases/population)*100 AS PositivityRate
FROM [Portfolio Project1]..CovidDeaths where Location like '%states%'
ORDER BY 1,2

--Looking at Countries with the Highest Infection Rate compared to Population
SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM [Portfolio Project1]..CovidDeaths 
--where Location like '%states%'
Group By Location, Population
ORDER BY PercentPopulationInfected desc

--Countries with Highest Death Counts
SELECT Location, MAX(cast(total_deaths as int)) AS HighestDeathCount
FROM [Portfolio Project1]..CovidDeaths 
--where Location like '%states%'
where continent is not null
Group By Location
ORDER BY HighestDeathCount desc

--Breakdown by Continent 

--Showing Continents with Highest Death Count
SELECT continent, MAX(cast(total_deaths as int)) AS HighestDeathCount
FROM [Portfolio Project1]..CovidDeaths 
--where Location like '%states%'
where continent is not null
Group By continent
ORDER BY HighestDeathCount desc


--Global Numbers (****issue of division by zero****)
SELECT date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths as INT)) AS total_deaths
CASE
	when SUM(new_cases) =0
	THEN NULL
	ELSE SUM(cast(new_deaths as INT))/SUM(new_cases)*100 AS DeathPercentage 
FROM [Portfolio Project1]..CovidDeaths
where continent is not null
Group By date
ORDER BY 1,2

--Global Numbers (***division by zero***)
SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) AS total_deaths,
SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM [Portfolio Project1]..CovidDeaths
where continent is not null 
GROUP BY date
order by 1,2

SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) AS total_deaths,
SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM [Portfolio Project1]..CovidDeaths
where continent is not null
order by 1,2

--Looking at Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM [Portfolio Project1]..CovidDeaths dea
JOIN [Portfolio Project1]..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--HAVING dea.location ='Canada'
ORDER BY 1,2,3

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM [Portfolio Project1]..CovidDeaths dea
JOIN [Portfolio Project1]..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 1,2,3



--USE CTE
With PopVsVac (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM [Portfolio Project1]..CovidDeaths dea
JOIN [Portfolio Project1]..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
---ORDER BY 1,2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentVaccinated FROM PopVsVac

--Temp Table 
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated 
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert Into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM [Portfolio Project1]..CovidDeaths dea
JOIN [Portfolio Project1]..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null

SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentVaccinated FROM #PercentPopulationVaccinated


---Creating View to store data for later
Create View PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
FROM [Portfolio Project1]..CovidDeaths dea
JOIN [Portfolio Project1]..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date=vac.date
--ORDER BY 2,3

SELECT * FROM PercentPopulationVaccinated