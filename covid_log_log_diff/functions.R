library(dplyr)
library(readr)

# DISCONTINUED loadCovidPerCountry because the ECDC switched to weekly data on 2020/12/14
# Previous source: "https://opendata.ecdc.europa.eu/covid19/casedistribution/csv"
# Maybe I can resurrect this later.

# Returns data frame with latest nytimes US state covid data.
# Output columns include:
# - date (as a date object)
# - state (as a string)
# - cases
# - newCasesPerDay (might be NA)
# If casesAsDeaths=TRUE than cases are actually deaths.
loadCovidPerUSState <- function(casesAsDeaths=FALSE) {
  covidByState <- read_csv('https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-states.csv')
  covidByState$date <- as.Date(covidByState$date)
  if (casesAsDeaths) {
    covidByState$cases <- covidByState$deaths # The hack
  }
  covidByState2 <- covidByState %>%
    group_by(state) %>%
    arrange(date, .by_group = TRUE) %>%
    mutate(prevDate = lag(date), prevCases = lag(cases))
  covidByState2$newCasesPerDay <- (covidByState2$cases - covidByState2$prevCases) / as.numeric(covidByState2$date - covidByState2$prevDate)
  covidByState2
}

# Returns data frame with latest nytimes US county covid data.
# Output columns include:
# - date (as a date object)
# - state (as a string)
# - cases
# - newCasesPerDay (might be NA)
# If casesAsDeaths=TRUE than cases are actually deaths.
loadCovidPerUSCounty <- function(casesAsDeaths=FALSE) {
  data <- read_csv('https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv')
  data$date <- as.Date(data$date)
  # Hack to get this to work quickly: put the county in the state column.
  # That should make it unique and also it will work in all other functions.
  # (Save the original state in "us_state")
  data$us_state <- data$state
  data$state <- paste0(data$us_state, ": ", data$county)
  # Only keep counties with > 10 rows of data.
  data <- data %>%
    group_by(state) %>%
    filter(n() >= 10)
  if (casesAsDeaths) {
    data$cases <- data$deaths # The hack
  }
  data <- data %>%
    group_by(state) %>%
    arrange(date, .by_group = TRUE) %>%
    mutate(prevDate = lag(date), prevCases = lag(cases))
  data$newCasesPerDay <- (data$cases - data$prevCases) / as.numeric(data$date - data$prevDate)
  
  arrange(data, state, date)
}

# Takes a data frame covidByState and returns a cleaned and smoothed version.
# Also adds a new "state" called ALL which is the sum.
# Assumes columns
# - date
# - state
# - cases
# - newCasesPerDay
# - deaths
cleanAndSmooth <- function(covidByState) {
  covidByState<-covidByState %>%
    dplyr::filter(!is.na(newCasesPerDay),
                  !is.na(cases),
                  !is.infinite(newCasesPerDay),
                  !is.nan(newCasesPerDay),
                  newCasesPerDay > 0,
                  cases > 0)
  
  snippet<-covidByState %>% group_by(date) %>%
    summarize(
      state = "_ALL_",
      cases = sum(cases),
      deaths=sum(deaths),
      newCasesPerDay = sum(newCasesPerDay)
    )
  
  covidByState = bind_rows(snippet, covidByState)
  
  # Need a minimum number of days of data for smoothing.
  covidByState<-covidByState %>%
    dplyr::group_by(state) %>%
    dplyr::filter(n() >= 10)
  # create loess-smoothed versions of time series for each state
  covidByStateSmoothed <- covidByState %>%
  #  filter(!(state %in% c("Northern Mariana Islands","Virgin Islands","Guam"))) %>%
    group_by(state) %>%
    do(data.frame(.,
                  smoothed = 10^predict(loess(log10(newCasesPerDay) ~ log10(cases), data = .), .))) %>%
    ungroup()
  covidByStateSmoothed
}

loadCovidDataByGeo <- function(geo) {
  if (geo=="US") {
    df <- loadCovidPerUSState(casesAsDeaths=FALSE)
  } else if (geo=="US_DEATHS") {
    df <- loadCovidPerUSState(casesAsDeaths=TRUE)
  } else if (geo=="WORLD") {
    df <- loadCovidPerCountry()
  } else if (geo=="US_COUNTY") {
    df <- loadCovidPerUSCounty(casesAsDeaths=FALSE)
  } else if (geo=="US_COUNTY_DEATHS") {
    df <- loadCovidPerUSCounty(casesAsDeaths=TRUE)
  } else {
    stop(paste0("Unrecognized geo: ", geo))
  }
  cleanAndSmooth(df)
}

loadCovidDataAndBackgroundByGeo <- function(geo) {
  if (geo=="US" || geo=="US_DEATHS") {
    background_states <- c("_ALL_", "New York", "California", "Michigan", "Louisiana", "Florida")
    list(covidByGeo=loadCovidDataByGeo(geo), background_geos=background_states)
  } else if (geo=="WORLD") {
    background_geos <- c("_ALL_", "Italy", "Germany", "South_Korea", "United_Kingdom", "United_States_of_America", "Brazil")
    list(covidByGeo=loadCovidDataByGeo(geo), background_geos=background_geos)
  } else if (geo=="US_COUNTY" || geo=="US_COUNTY_DEATHS") {
    background_geos <- c("_ALL_", "New York: New York City")
    list(covidByGeo=loadCovidDataByGeo(geo), background_geos=background_geos)
  } else {
    stop(paste0("Unrecognized geo: ", geo))
  }
}
