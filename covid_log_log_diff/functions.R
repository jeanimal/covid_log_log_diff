library(dplyr)

# Returns data frame with latest nytimes per state covid data.
# Output columns include:
# - date (as a date object)
# - state (as a string)
# - cases
# - newCasesPerDay (might be NA)
loadCovidPerCountry <- function() {
  data <-read.csv("https://opendata.ecdc.europa.eu/covid19/casedistribution/csv", na.strings = "", fileEncoding = "UTF-8-BOM", stringsAsFactors =FALSE)
  data$date <- ISOdate(data$year, data$month, data$day)
  # Only keep countries with > 10 rows of data.
  data <- data %>%
    group_by(geoId) %>%
    filter(n() >= 10)
  # Their 'cases' column is actually new cases.
  data$newCasesPerDay <- data$cases
  data <- data %>%
    group_by(geoId) %>%
    arrange(date, .by_group = TRUE) %>%
    mutate(totalCases = cumsum(newCasesPerDay))
  data$cases <- data$totalCases
  data$fips <- data$geoId
  data$state <- data$countriesAndTerritories
  arrange(data, state, date)
}

loadAndFormatNytimesCovidPerState <- function() {
  covidByState <- read.csv2('https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-states.csv', 
                            sep=",",
                            stringsAsFactors =FALSE)
  covidByState$date <- as.Date(covidByState$date)
  covidByState2 <- covidByState %>%
    group_by(state) %>%
    arrange(date, .by_group = TRUE) %>%
    mutate(prevDate = lag(date), prevCases = lag(cases))
  covidByState2$newCasesPerDay <- (covidByState2$cases - covidByState2$prevCases) / as.numeric(covidByState2$date - covidByState2$prevDate)
  covidByState2
}

loadCovidPerUSCounty <- function() {
  data <- read.csv2('https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv',
                    sep=",",
                    stringsAsFactors =FALSE)
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

loadCovidDataBy2Geo <- function(geo) {
  if (geo=="US") {
    df <- loadAndFormatNytimesCovidPerState()
  } else if (geo=="WORLD") {
    df <- loadCovidPerCountry()
  } else if (geo=="US_COUNTY") {
    df <- loadCovidPerUSCounty()
  } else {
    stop(paste0("Unrecognized geo: ", geo))
  }
  cleanAndSmooth(df)
}

loadCovidDataAndBackgroundByGeo <- function(geo) {
  if (geo=="US") {
    background_states <- c("_ALL_", "New York", "New Jersey", "California", "Michigan", "Louisiana", "Florida", "Massachusetts", "Illinois", "Pennsylvania", "Washington")
    list(covidByGeo=loadCovidDataBy2Geo(geo), background_geos=background_states)
  } else if (geo=="WORLD") {
    background_geos <- c("_ALL_", "Italy", "Germany", "China", "South_Korea", "United_Kingdom", "United_States_of_America")
    list(covidByGeo=loadCovidDataBy2Geo(geo), background_geos=background_geos)
  } else if (geo=="US_COUNTY") {
    background_geos <- c("_ALL_", "New York: New York City")
    list(covidByGeo=loadCovidDataBy2Geo(geo), background_geos=background_geos)
  } else {
    stop(paste0("Unrecognized geo: ", geo))
  }
}
