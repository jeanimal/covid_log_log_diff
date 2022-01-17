#
# This is the server logic of a Shiny web application.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(ggplot2)
library(plotly)
library(scales)
source("functions.R")

# Pre-load data.
# The number is the degree of loess smoothing, which can range from 0 to 1 (most smooth).
# The values were manually tuned by looking at graphs of Florida data.
outputListUS <- loadCovidDataAndBackgroundByGeo("US", 0.2)
outputListUSDeaths <- loadCovidDataAndBackgroundByGeo("US_DEATHS", 0.3)
# outputListWorld <- loadCovidDataAndBackgroundByGeo("WORLD")
# outputListUSCounty <- loadCovidDataAndBackgroundByGeo("US_COUNTY", 1.0)
# outputListUSCountyDeaths <- loadCovidDataAndBackgroundByGeo("US_COUNTY_DEATHS", 1.0)

getOutputListByGeo <- function(geo) {
  if (geo == "US") {
    return(outputListUS)
  } else if (geo == "US_DEATHS") {
    return(outputListUSDeaths)
#  } else if (geo == "WORLD") {
#    return(outputListWorld)
#  } else if (geo=="US_COUNTY") {
#    return(outputListUSCounty)
#  } else if (geo=="US_COUNTY_DEATHS") {
#    return(outputListUSCountyDeaths)
  } else {
    stop(paste0("Unrecognized geo: ", geo))
  }
}

server <- function(input, output, session) {
  observe({
    covidByStateSmoothed <- getOutputListByGeo(input$geo)$covidByGeo
    updateSelectInput(session, "state", label = "State/Country/County:", choices = unique(covidByStateSmoothed$state))
  })
  output$plot1 <- renderPlotly({
    covidByStateSmoothed <- getOutputListByGeo(input$geo)$covidByGeo
    background_states <- getOutputListByGeo(input$geo)$background_geos
    
    selected_state <- input$state
    if (!selected_state %in% unique(covidByStateSmoothed$state)) {
      # Don't plot yet because "state" select input is still loading.
      return()
    }
    background_states <- setdiff(background_states, selected_state)
    
    plot_data <- covidByStateSmoothed %>%
      filter(state %in% background_states) %>%
      ungroup() %>%
      arrange(state, date) %>%
      mutate(state = as.factor(state),
             state = reorder(state, -newCasesPerDay, last))
    
    d <- plot_data %>%
      highlight_key(~state)
    
    covidByStateSmoothMostRecent <- plot_data %>%
      group_by(state) %>%
      arrange(desc(date)) %>%
      slice(1) %>%
      ungroup()
    
    # ggplot will complain about ignoring an unknown aesthetic
    # this is a side effect of a hack to get tooltips to show up in plotly
    # so supress warnings as a workaround
    
    suppressWarnings(
    p <- covidByStateSmoothed %>%
      filter(state == selected_state) %>%
      ggplot(aes(x=cases, y=smoothed)) +
      geom_point(data = d, aes(group = state, color = state, text = sprintf('%s on %s:\n%s total cases\n%s new cases', state, date, comma(cases), comma(newCasesPerDay))), size = 0.3, alpha = 1) +
      geom_line(data = d, aes(group = state, color = state), alpha = 0.5) +
      geom_point(data = covidByStateSmoothMostRecent, aes(x = cases, y = smoothed, group = state, color = state), size = 2, alpha = 0.5) +
      geom_line(aes(y = smoothed), color = "black") +
      geom_point(aes(x = last(cases), y = last(smoothed)), size = 2, color = "black", alpha = 0.5) +
      geom_text(aes(x = last(cases), y = 1.3*last(smoothed), label = state)) +
      geom_point(aes(y = smoothed, text = sprintf('%s on %s:\n%s total cases\n%s new cases', state, date, comma(cases), comma(newCasesPerDay))),size = 0.3, alpha = 1) +
      scale_x_log10(label = comma) + 
      scale_y_log10(label = comma) +
      coord_equal() +
      theme_minimal() +
      labs(x = 'Total confirmed cases',
           y = 'New confirmed cases per day',
           title = paste0('Trajectory of COVID-19 cases for ', selected_state))
    )
    #p
    
    # convert to plotly for interactivity
    fig <- ggplotly(p, tooltip = "text") %>% config(displayModeBar = F) %>% layout(xaxis=list(fixedrange=TRUE)) %>% layout(yaxis=list(fixedrange=TRUE))
  })
}
