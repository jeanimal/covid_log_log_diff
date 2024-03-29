# Covid log-log-diff plots

This app plots covid-19 trends in a way that makes it easier to
see if we are flattening the growth.  As long as the points march
in a straight line, the exponential growth is constant.  When the
points head down, our social distancing is working. 

A full explanation and animated plots per country are in this video:
How To Tell If We're Beating COVID-19: https://www.youtube.com/watch?v=54XLXg4fYsc&fbclid=IwAR1WWk6EBv84psWs_Bw83JsuRQlbI615gAk94CSpit-U3ywNEUDxC1WpcdY

# Data

We provide functions to standardize data at three geographic levels:
* Countries of the world.  Data is from the ECDC: https://opendata.ecdc.europa.eu/covid19/casedistribution/csv
* States of the United States of America. Data is from the New York Times: https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-states.csv
* Counties of the United States of America, by state.  Data is from the New York Times: https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv


# Authors

* [Jean Czerlinski Whitmore](https://github.com/jeanimal)
* [Jake Hofman](https://github.com/jhofman)
* [Dan Goldstein](https://github.com/dggoldst)

# License

This project is licensed under the MIT License-- see the [LICENSE](LICENSE) file.
