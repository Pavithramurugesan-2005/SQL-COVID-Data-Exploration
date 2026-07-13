select*from
[portfolio project].dbo.CovidDeaths
where continent is not null
order by 3,4

--select*from[portfolio project].dbo.CovidVaccinations order by 3,4
--now we are going to select the data we are going to use	

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM [portfolio project].dbo.CovidDeaths
order by 1,2

--looking at total case vs total deaths
--by using where and we are filtering the data in our country from lot of location across the world
SELECT  location,date,total_cases,  total_deaths,(total_deaths/total_cases)*100 as deathpercentage
FROM [portfolio project].dbo.CovidDeaths
where location like '%india%'
and continent is not null
order by 1,2


UPDATE [portfolio project].dbo.CovidDeaths
SET total_cases = NULL
WHERE LTRIM(RTRIM(total_cases)) = '';

UPDATE [portfolio project].dbo.CovidDeaths
SET total_deaths = NULL
WHERE LTRIM(RTRIM(total_deaths)) = '';

ALTER TABLE [portfolio project].dbo.CovidDeaths
ALTER COLUMN total_cases FLOAT;

ALTER TABLE [portfolio project].dbo.CovidDeaths
ALTER COLUMN total_deaths FLOAT;

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'CovidDeaths';

--looking at total case vs population
SELECT  location,date,population,total_cases, (total_cases/population)*100 as percentpopulationinfected
FROM [portfolio project].dbo.CovidDeaths
--where location like '%india%'
order by 1,2


--looking at country which has highest infected rate when compared to population
SELECT
    Location,
    Population,
    MAX(total_cases) AS HighestInfectionCount,
    MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM [portfolio project].dbo.CovidDeaths
GROUP BY Location, Population
ORDER BY PercentPopulationInfected desc

--showing country with highest death rate with per population
SELECT
    Location,
    MAX(total_deaths) AS totaldeathcountCount
FROM [portfolio project].dbo.CovidDeaths
where continent is not null
GROUP BY Location
ORDER BY totaldeathcountCount desc

--let break things by continent
SELECT
    continent,
    MAX(total_deaths) AS totaldeathcountCount
FROM [portfolio project].dbo.CovidDeaths
where continent is not null
GROUP BY continent
ORDER BY totaldeathcountCount desc

--global numbers
SELECT  date,sum(cast(new_cases as int)),sum(cast(new_deaths as int)),sum(cast(new_deaths as int))/sum(cast(new_cases as int))*100 as deathpercentage
FROM [portfolio project].dbo.CovidDeaths
--where location like '%states%'
where continent is not null
group by date
order by 1,2

--look at total vaccination vs population

select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,sum(convert(int,vac.new_vaccinations)) 
over (partition by dea.location order by dea.location,dea.date)as  rollingpeoplevaccinated --(rollingpeoplevaccinated/population)/100
from
.CovidDeaths dea
join CovidVaccinations vac
on dea.location=vac.location
and dea.date=vac.date
where dea.continent is not null
order by 2,3


-- Using CTE to perform Calculation on Partition By in previous query
WITH PopvsVac
(
    Continent,
    Location,
    Date,
    Population,
    New_Vaccinations,
    RollingPeopleVaccinated
)
AS
(
    SELECT
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(CONVERT(INT, vac.new_vaccinations))
        OVER (
            PARTITION BY dea.location
            ORDER BY dea.location, dea.date
        ) AS RollingPeopleVaccinated
    FROM [portfolio project].dbo.CovidDeaths dea
    JOIN [portfolio project].dbo.CovidVaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)

SELECT *,
       (RollingPeopleVaccinated / Population) * 100 AS VaccinatedPercentage
FROM PopvsVac;

-- Using Temp Table to perform Calculation on Partition By in previous query

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
INSERT INTO #PercentPopulationVaccinated
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(INT, vac.new_vaccinations))
        OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM [portfolio project].dbo.CovidDeaths dea
JOIN [portfolio project].dbo.CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date;

SELECT *,
       (RollingPeopleVaccinated / Population) * 100 AS VaccinationPercentage
FROM #PercentPopulationVaccinated;


-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(INT, vac.new_vaccinations))
        OVER (
            PARTITION BY dea.location
            ORDER BY dea.location, dea.date
        ) AS RollingPeopleVaccinated
FROM [portfolio project].dbo.CovidDeaths dea
JOIN [portfolio project].dbo.CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;
