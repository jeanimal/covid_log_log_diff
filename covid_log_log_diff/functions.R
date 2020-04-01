library(dplyr)

# Loads latest nytimes per state covid data.
# Output columns include:
# - date (as a date object)
# - state (as a string)
# - cases
# - newCasesPerDay (might be NA)
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
