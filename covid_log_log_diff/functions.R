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
  # Their 'cases' column is actually new cases.
  data$newCasesPerDay <- data$cases
  data <- data %>%
    group_by(geoId) %>%
    arrange(date, .by_group = TRUE) %>%
    mutate(totalCases = cumsum(newCasesPerDay))
  data$cases <- data$totalCases
  data$fips <- data$geoId
  data$state <- data$countriesAndTerritories
  # Drop countries with too few rows of data.
  data <- data %>%
    group_by(geoId) %>%
    filter(n() >= 10)
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

background_states <- c("USA", "New York", "New Jersey", "California", "Michigan", "Louisiana", "Florida", "Massachusetts", "Illinois", "Pennsylvania", "Washington")

background_states <- c("Italy", "Germany", "China", "South_Korea", "United_Kingdom", "United_States_of_America")



loadCovidDatabyGeo <- function(geo) {
  if (geo=="US") {
    df <- loadAndFormatNytimesCovidPerStateOld()
    background_states <- c("ALL", "New York", "New Jersey", "California", "Michigan", "Louisiana", "Florida", "Massachusetts", "Illinois", "Pennsylvania", "Washington")
    list(covidByGeo=df, background_geos=background_states)
  } else if (geo=="WORLD") {
    df <- loadCovidPerCountry()
    background_geos <- c("ALL", "Italy", "Germany", "China", "South_Korea", "United_Kingdom", "United_States_of_America")
    list(covidByGeo=df, background_geos=background_geos)
  } else {
    stop(paste0("Unrecognized geo: ", geo))
  }
}

