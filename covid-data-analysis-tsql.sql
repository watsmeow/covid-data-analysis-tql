-- COVID DEATHS TABLE

SELECT *
from PortfolioProject..CovidVaccinations
order by 3,4

ALTER TABLE CovidDeaths
ALTER COLUMN date DATE

ALTER TABLE CovidDeaths
ALTER COLUMN total_cases float

ALTER TABLE CovidDeaths
ALTER COLUMN total_deaths float

ALTER TABLE CovidDeaths
ALTER COLUMN new_cases float

ALTER TABLE CovidDeaths
ALTER COLUMN new_deaths float

ALTER TABLE CovidVaccinations
ALTER COLUMN date DATE

ALTER TABLE CovidVaccinations
ALTER COLUMN new_vaccinations float

--Select data that is used
Select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths
Where continent is not null
order by 1, 2


--Total cases vs Total deaths:
--shows likelihood of dying of contracting covid in specific country
Select
	location,
	date,
	(total_deaths/total_cases)*100 as death_percentage
From PortfolioProject..CovidDeaths
WHERE total_cases is not NULL and total_cases > 0 and total_deaths is not NULL and location = 'Germany'
order by 1, 2

--Total cases vs population:
--shows what percentage of population of country was diagnosed with covid
Select
	location,
	date,
	population,
	total_cases,
	(total_cases/population)*100 as percent_of_population_diagnosed
From PortfolioProject..CovidDeaths
WHERE population > 0 and total_cases > 0 and location = 'Germany'
order by 5 DESC

--Highest infection rates compared to population of country
Select
	location, 
	population,
	MAX(total_cases) as highest_infection_count,
	MAX((total_cases/population))*100 as percent_of_pop_infected
From PortfolioProject..CovidDeaths
Group by population, location
Order by percent_of_pop_infected DESC

--Highest death count per population
Select
	location, 
	MAX(total_deaths) as total_death_count
From PortfolioProject..CovidDeaths
where continent != ''
Group by location
Order by total_death_count DESC

--Death count by continent
Select
	continent, 
	MAX(total_deaths) as total_death_count
From PortfolioProject..CovidDeaths
where continent != ''
Group by continent
Order by total_death_count DESC

--Global numbers
Select 
	date,
	SUM(new_cases) as new_cases, SUM(new_deaths) as new_deaths,
	SUM(new_deaths)/SUM(new_cases)*100 as death_percentage
From PortfolioProject..CovidDeaths
Where new_cases > 0 and new_deaths > 0 and continent != ''
Group by date
Order by 1, 2


-- COVID VACCINATIONS TABLE
Select *
From PortfolioProject..CovidDeaths cds
Join PortfolioProject..CovidVaccinations cvs
	On cds.location = cvs.location
	and cds.date = cvs.date

--World population vs vaccinations
Select cds.continent, 
	cds.location, cds.date, 
	cds.population, 
	cvs.new_vaccinations,
	SUM(cvs.new_vaccinations) 
	OVER (Partition by cds.location Order by cds.location, cds.date) as total_population_vaccinated
From PortfolioProject..CovidDeaths cds
Join PortfolioProject..CovidVaccinations cvs
	On cds.location = cvs.location
	and cds.date = cvs.date
Where cds.continent != ''
Order by 2, 3


--Use CTE for percentage of population vaccinated
With total_pop_vs_total_vaxxed(continent, location, date, population, new_vaccinations, total_population_vaccinated) 
as
(
Select cds.continent, 
	cds.location, cds.date, 
	cds.population, 
	cvs.new_vaccinations,
	SUM(cvs.new_vaccinations) 
	OVER (Partition by cds.location Order by cds.location, cds.date) as total_population_vaccinated
From PortfolioProject..CovidDeaths cds
Join PortfolioProject..CovidVaccinations cvs
	On cds.location = cvs.location
	and cds.date = cvs.date
Where cds.continent != '' and cvs.new_vaccinations != 0
)
Select 
	*, 
	(total_population_vaccinated/population)*100
from total_pop_vs_total_vaxxed

--Temp table
Create  Table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date date,
population float,
new_vaccinations float,
total_population_vaccinated float
)
Insert into #PercentPopulationVaccinated
Select cds.continent, 
	cds.location, cds.date, 
	cds.population, 
	cvs.new_vaccinations,
	SUM(cvs.new_vaccinations) 
	OVER (Partition by cds.location Order by cds.location, cds.date) as total_population_vaccinated
From PortfolioProject..CovidDeaths cds
Join PortfolioProject..CovidVaccinations cvs
	On cds.location = cvs.location
	and cds.date = cvs.date
Where cds.continent != '' and cvs.new_vaccinations != 0

Select 
	*, 
	(total_population_vaccinated/population)*100 as percentage_pop_vaxxed
from #PercentPopulationVaccinated

--View for visualizations
Create view PercentPopulationVaccinated as 
Select cds.continent, 
	cds.location, cds.date, 
	cds.population, 
	cvs.new_vaccinations,
	SUM(cvs.new_vaccinations) 
	OVER (Partition by cds.location Order by cds.location, cds.date) as total_population_vaccinated
From PortfolioProject..CovidDeaths cds
Join PortfolioProject..CovidVaccinations cvs
	On cds.location = cvs.location
	and cds.date = cvs.date
