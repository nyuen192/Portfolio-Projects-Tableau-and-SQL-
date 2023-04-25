--View covid death columns 
Select Location, date, total_cases, new_cases, total_deaths, population
From Portfolio_Yuen..CovidDeaths
order by 1,2

--Reference data type check for each database column 
Select
	TABLE_CATALOG
	,TABLE_SCHEMA
	,TABLE_NAME
	,COLUMN_NAME
	,DATA_TYPE
	,CHARACTER_MAXIMUM_LENGTH
	,NUMERIC_PRECISION
From INFORMATION_SCHEMA.COLUMNS
Where TABLE_NAME = 'CovidDeaths' and COLUMN_NAME = 'Total_deaths' or  TABLE_NAME = 'CovidDeaths' and COLUMN_NAME = 'Total_cases' 

--Analyzing Total Covid Cases vs Total Deaths; Indicates likelihood of dying if covid is contracted in U.S. 
Select Location, date, total_cases, total_deaths, 
	CAST (total_deaths AS FLOAT) / CAST(total_cases AS FLOAT)*100 as DeathPercentage
From Portfolio_Yuen..CovidDeaths
Where Location like '%states%' and continent is not null
order by 1,2

--Looking at Total Cases vs Population; Displays what percentage of population was impacted by covid 
Select Location, date, total_cases, population, 
	CAST (total_cases AS FLOAT) / (population)*100 as PercentPopulationInfected
From Portfolio_Yuen..CovidDeaths
Where Location like '%states%' and continent is not null
order by 1,2

--Analyzing countries with highest covid infection rate compared to population
SELECT Location, population, MAX(total_cases) as HighestInfectionCount, 
	MAX(CAST(total_cases AS FLOAT) / population)*100 as PercentPopulationInfected 
FROM Portfolio_Yuen..CovidDeaths
Where continent is not null
GROUP BY Location, Population
ORDER BY PercentPopulationInfected desc 

--Analyzing countries with Highest Death Count per Population
SELECT Location, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM Portfolio_Yuen..CovidDeaths
Where continent is not null
GROUP BY Location
ORDER BY TotalDeathCount desc 

--Analyzing continents with Highest Death Count per population 
SELECT continent, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM Portfolio_Yuen..CovidDeaths
Where continent is not null
GROUP BY continent
ORDER BY TotalDeathCount desc 

--GLOBAL NUMBERS
Select SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, 
	SUM(new_deaths)/NULLIF(SUM(new_cases),0)*100 as DeathPercentage
FROM Portfolio_Yuen..CovidDeaths
Where continent is not null
Group By date
order by 1,2

--Analyzing Total Popuation vs Vaccinations using CTE 
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as 
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order 
		by dea.location, dea.Date) as RollingPeopleVaccinated
From Portfolio_Yuen..CovidDeaths dea
JOIN Portfolio_Yuen..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
)
Select * RollingPeopleVaccinated/Population)*100
From PopvsVac

--TEMP TABLE
DROP Table if exists #PercentPopulationVaccinated  
Create Table #PercentPopulationVaccinated 
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric, 
RollingPeopleVaccinated numeric 
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order 
		by dea.location, dea.Date) as RollingPeopleVaccinated
From Portfolio_Yuen..CovidDeaths dea
JOIN Portfolio_Yuen..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date

Select * RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

--Creating View to store data for Tableau visualizations 
Create View PercentPopulationVaccinated as 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order 
		by dea.location, dea.Date) as RollingPeopleVaccinated
From Portfolio_Yuen..CovidDeaths dea
JOIN Portfolio_Yuen..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
