library(dplyr)

# Returns data frame with latest nytimes per state covid data.
# Output columns include:
# - date (as a date object)
# - state (as a string)
# - cases
# - newCasesPerDay (might be NA)
loadAndFormatNytimesCovidPerState <- function() {
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
    filter(n() >= 30)
  arrange(data, state, date)
}

loadAndFormatNytimesCovidPerStateOld <- function() {
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

