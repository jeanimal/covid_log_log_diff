#
# This is the server logic of a Shiny web application.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(ggplot2)
library(scales)
source("functions.R")

covidByState <- loadAndFormatNytimesCovidPerState()

covidByState<-covidByState %>% 
  dplyr::filter(!is.na(newCasesPerDay), 
                !is.na(cases), 
                newCasesPerDay > 0, 
                cases > 0)  %>%
  dplyr::select(-fips,-prevDate,-prevCases)

snippet<-covidByState %>% group_by(date) %>% 
  summarize(
    state = "USA",
    cases = sum(cases),
    deaths=sum(deaths),
    newCasesPerDay = sum(newCasesPerDay)
    )

covidByState = bind_rows(snippet, covidByState)

server <- function(input, output) {
  output$plot1 <- renderPlot({
    data <- covidByState[which(covidByState$state %in% input$state), ]
    p <- ggplot(data, aes(cases, newCasesPerDay+0, color = state)) +
         theme_bw() +
         geom_point() + 
         scale_x_log10(label = comma) + 
         scale_y_log10(label = comma) +
         geom_smooth(se = FALSE) +
         theme(legend.position = "none") +
         labs(x = "Total Cases", y="New Cases Per Day") +
         coord_fixed()
    if (input$showDates) {
      p <- p + geom_text(label = data$date, check_overlap = T)
    }
    p
  })
}
