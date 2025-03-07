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

### Print Code to Download Data from a Table URL

You can use `pxwebtools` to print pxweb query templates and download pxweb data
in more convenient format than directly with `pxweb` package.

First, you can print query template using `pxw_print_code_full_query_c` 
with pxweb webpage url or with api url. Query with all possible level for all
variables is printed and copied to clipboard. 

This function generates R code to download a `data.frame` from a PxWeb API using 
PxWeb web page url to a table or API url. Code is copied to clipboard.

#### Parameters

- `url`: A PxWeb API URL to the table or a web interface URL.
- `time_all`: If `TRUE` (default), the time variable is set to `c("*")`.


#### Example Usage

```r
library(pxwebtools)

pxw_print_code_full_query_c("https://pxdata.stat.fi/PxWeb/pxweb/en/StatFin/StatFin__tyti/statfin_tyti_pxt_11pk.px/")

```
```r
dat_statfin_tyti_pxt_11pk_px <- pxw_get_data(
  url = "https://pxdata.stat.fi/PxWeb/api/v1/en/StatFin/tyti/statfin_tyti_pxt_11pk.px/",
  query = 
    list("Vuosi"=c("*"),
       "Sukupuoli"=c("SSS","1","2"),
       "Tiedot"=c(
          "Palkansaajat_yht",
          "Jva_kokoaikatyo",
          "Jva_osaaikatyo",
          "Jva_tyo",
          "Ma_kokoaikatyo",
          "Ma_osaaikatyo",
          "Ma_tyo",
          "Kokoaikatyo_yht",
          "Osaaikatyo_yht",
          "Jva_kokoaikatyo_pros",
          "Jva_osaaikatyo_pros",
          "Jva_tyo_pros",
          "Ma_kokoaikatyo_pros",
          "Ma_osaaikatyo_pros",
          "Ma_tyo_pros",
          "Kokoaikatyo_yht_pros",
          "Osaaikatyo_yht_pros"
          )))
```

Code template can be pasted and modified:

```r

dat_statfin_tyti_pxt_11pk_px <- pxw_get_data(
  url = "https://pxdata.stat.fi/PxWeb/api/v1/en/StatFin/tyti/statfin_tyti_pxt_11pk.px/",
  query = 
    list("Vuosi"=c("*"),
       "Sukupuoli"=c("SSS","1","2"),
       "Tiedot"=c(
          "Palkansaajat_yht",
          "Kokoaikatyo_yht"
          )))
          
```

Resulting data:

```r

str(dat_statfin_tyti_pxt_11pk_px)

tibble [96 × 4] (S3: tbl_df/tbl/data.frame)
 $ time     : Date[1:96], format: "2009-01-01" "2009-01-01" "2009-01-01" "2009-01-01" ...
 $ sukupuoli: Factor w/ 3 levels "SSS","1","2": 1 1 2 2 3 3 1 1 2 2 ...
 $ tiedot   : Factor w/ 2 levels "Palkansaajat_yht",..: 1 2 1 2 1 2 1 2 1 2 ...
 $ values   : num [1:96] 2091 1809 1013 931 1078 ...
 - attr(*, "codes_names")=List of 2
  ..$ sukupuoli: Named chr [1:3] "Total" "Males" "Females"
  .. ..- attr(*, "names")= chr [1:3] "SSS" "1" "2"
  ..$ tiedot   : Named chr [1:17] "Employees total, 1000 persons" "Employees, permanent full-time work, 1000 persons" "Employees, permanent part-time work, 1000 persons" "Employees, permanent work total, 1000 persons" ...
  .. ..- attr(*, "names")= chr [1:17] "Palkansaajat_yht" "Jva_kokoaikatyo" "Jva_osaaikatyo" "Jva_tyo" ...

```

### Labels of codes in data

```r

code_table  <- pxw_codes_names_table(dat_statfin_tyti_pxt_11pk_px, "tiedot")
print(code_table)

```

### Converting PxWeb URLs to API URLs

The `url_web2api()` function converts a PxWeb web interface URL into an API-compatible URL:

```r


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



## Contributing

Contributions to `pxwebtools` are welcome! Feel free to:

1. Fork the repository on GitHub.
2. Make changes or add new features.
3. Submit a pull request with a clear description of your changes.

## License

`pxwebtools` is licensed under the MIT License. See the `LICENSE` file for details.

## Acknowledgments

- The `pxwebtools` package builds on the `pxweb`, `statfitools` and `pttdatahaku` package and the PxWeb API framework used by various statistical services.

