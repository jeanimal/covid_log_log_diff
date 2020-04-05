# Data

We would prefer if all data were externally sourced.  But it's not always available.  In the mean time, we are hosting some of our own data.

## State mandates

```covid_state_mandates.csv``` is manually-entered data for several states sourced from
https://covid19.healthdata.org/projections

There are four categories of mandates tracked:
- Stay at home order, called "stayhome" in the csv
- Educational facilities closed, called "schools" in the csv
- Non-essential services closed, called "nonessential" in the csv
- Travel severely limited, called "travel" in the csv

The data also includes fips geographic codes: https://transition.fcc.gov/oet/info/maps/census/fips/fips.txt

The healthdata.org website explains:

These dates pertain only to government-mandated measures implemented for the entire population within the selected location.

For example:
- If a stay-at-home order is issued only for the elderly, since this is not a general population order, the coding would be Not implemented.
- If a school-closure order is issued at the city level, but not at the government level of the selected location, the coding would be Not implemented.
