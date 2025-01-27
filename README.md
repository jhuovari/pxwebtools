# pxwebtools

`pxwebtools` is an R package that provides utility functions for working with PxWeb databases, making it easier to construct and interact with queries programmatically. PxWeb is widely used by statistical services such as Statistics Finland and Statistics Sweden to provide access to statistical data through web interfaces and APIs.

## Features

- Convert PxWeb web interface URLs to API-compatible URLs.
- Simplify the process of building queries for PxWeb APIs.
- Work with PxWeb metadata and streamline API interactions.


## Installation

To install the development version of `pxwebtools` from GitHub:

```r
# Install devtools if not already installed
install.packages("devtools")

# Install pxwebtools from GitHub
devtools::install_github("jhuovari/pxwebtools")
```

## Usage

### Converting PxWeb URLs to API URLs

The `url_web2api()` function converts a PxWeb web interface URL into an API-compatible URL:

```r
library(pxwebtools)

# Example 1: StatFin database
web_url <- "https://pxdata.stat.fi/PxWeb/pxweb/fi/StatFin/StatFin__ati/statfin_ati_pxt_11zt.px"
api_url <- url_web2api(web_url)
cat(api_url)
# Output: "https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/ati/statfin_ati_pxt_11zt.px"

# Example 2: LUKE database
web_url <- "https://statdb.luke.fi/PxWeb/pxweb/fi/LUKE/LUKE__04%20Metsa__02%20Rakenne%20ja%20tuotanto__06%20Puun%20markkinahakkuut__04%20Vuositilastot/01a_Teollisuuspuun_hakkuut_maak_v.px/"
api_url <- url_web2api(web_url)
cat(api_url)
# Output: "https://statdb.luke.fi/PxWeb/api/v1/fi/LUKE/04%20Metsa/02%20Rakenne%20ja%20tuotanto/06%20Puun%20markkinahakkuut/04%20Vuositilastot/01a_Teollisuuspuun_hakkuut_maak_v.px"
```

### Building and Sending Queries

You can use `pxwebtools` in combination with the `pxweb` package to build and execute queries. Below is an example workflow:

```r
library(pxwebtools)
library(pxweb)

# Convert a web URL to an API URL
web_url <- "https://pxdata.stat.fi/PxWeb/pxweb/fi/StatFin/StatFin__ati/statfin_ati_pxt_11zt.px"
api_url <- url_web2api(web_url)

# Fetch metadata for the table
metadata <- pxweb_get(api_url)

# Build a query
query <- list(
  Vuosi = c("2020", "2021"),
  Alue = c("001", "002"),
  Tiedot = c("1", "2")
)

# Download data
result <- pxweb_get(api_url, query = pxweb_query(query))

# View the result
print(result)
```

## Contributing

Contributions to `pxwebtools` are welcome! Feel free to:

1. Fork the repository on GitHub.
2. Make changes or add new features.
3. Submit a pull request with a clear description of your changes.

## License

`pxwebtools` is licensed under the MIT License. See the `LICENSE` file for details.

## Acknowledgments

- The `pxwebtools` package builds on the `pxweb`, `statfitools` and `pttdatahaku` package and the PxWeb API framework used by various statistical services.


