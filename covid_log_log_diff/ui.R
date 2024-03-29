#
# This is the user-interface definition of a Shiny web application.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)
library(plotly)
library(shinycssloaders)
source("functions.R")

# Define UI for showing log-log-diff plots of covid cases.
ui <- fluidPage(
  titlePanel("Plotting when covid-19 growth trend slows"),
  helpText("This app plots covid-19 trends in a way that makes it easier to ",
           "see if we are flattening the growth.  As long as the points march ",
           "in a straight line, the exponential growth is constant.  When the ",
           "points head down, our social distancing is working.  ",
           "A full explanation and animated plots per country are in this video: "),
  helpText(a("How To Tell If We're Beating COVID-19", target="_blank",
             href="https://www.youtube.com/watch?v=54XLXg4fYsc&fbclid=IwAR1WWk6EBv84psWs_Bw83JsuRQlbI615gAk94CSpit-U3ywNEUDxC1WpcdY")
           ),
  selectInput("geo", "Cases or deaths:",
              c("US", "US_DEATHS")),
  selectInput("state", "State",
              c("_ALL_")),
  plotlyOutput("plot1", width = "auto", height = "auto", inline = TRUE)  %>% withSpinner(color="#0dc5c1"),
  hr(),
  helpText("US state data is from the nytimes: ",
             a("https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-states.csv",
             href="https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-states.csv")),
  # helpText("World country data is from the ECDC:",
  #         a("https://opendata.ecdc.europa.eu/covid19/casedistribution/csv",
  #           href="https://opendata.ecdc.europa.eu/covid19/casedistribution/csv")),
  helpText("The shiny app to generate the plots is at: ",
           a("https://github.com/jeanimal/covid_log_log_diff/",
             href="https://github.com/jeanimal/covid_log_log_diff/"))
)
