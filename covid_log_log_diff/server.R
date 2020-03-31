#
# This is the server logic of a Shiny web application.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)
library(ggplot2)
source("functions.R")

covidByState <- loadAndFormatNytimesCovidPerState()

server <- function(input, output) {
  output$plot1 <- renderPlot({
    data <- covidByState[which(covidByState$state %in% input$state),]
    p <- ggplot(data, aes(cases, newCasesPerDay, color=state)) + 
      geom_point() + scale_x_log10() + scale_y_log10()
    if (input$showDates) {
      p <- p + geom_text(label=data$date, check_overlap = T)
    }
    p
    # ggplot(covidByState, aes(cases, newCasesPerDay, color=as.factor(state))) + geom_point() + scale_x_log10() + scale_y_log10()
  })
}
