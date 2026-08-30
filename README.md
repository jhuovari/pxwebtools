
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

## The Statistics Finland API change of 8 June 2026

Statistics Finland changed the structure of the px files of its active
databases on 8 June 2026. The change affects API queries only, the web
interface is used as before. In short:

- **Table file names, `TABLEID` and `MATRIX` identifiers were shortened.**
  In StatFin the table file `statfin_ton_pxt_111e.px` became `111e.px`.
- **Every variable got a variable code**, which replaced the variable name as
  the identifier of the variable in an API query. The content variable
  `Tiedot` is now `contentscode`, the time variable is `timeperiod_y`,
  `timeperiod_q` or `timeperiod_m` depending on the frequency of the table, and
  a classification variable uses the identifier of the code list of the
  classification.
- **Some value codes of classification variables got a prefix.**

The StatFin archive database (`StatFin_Passiivi`) was not changed.

`pxwebtools` works with the current API and keeps older code working:

- Table URLs written in the old long form are shortened automatically.
- Query variables given by their old name are matched to the variable code of
  the table, and value codes are matched to prefixed value codes.
- The time variable is found from the table metadata, so `time_all` works
  regardless of what the time variable is called.

The safest way to write a new query is to print a query template with
`pxw_print_code_full_query_c()`, which always uses the codes of the table as
they are in the API right now.

See Statistics Finland's own instructions:
[PxWeb-tietokantojen rajapintakäyttöön muutoksia 8.6.](https://stat.fi/fi/uutinen/PxWeb-tietokantojen-rajapintakaeyttoeoen-muutoksia-86-muuta-rajapintakyselyt-ohjeen-mukaan)
/ [Changes to interface use of PxWeb databases on 8 June](https://stat.fi/en/news/Changes-to-interface-use-of-PxWeb-databases-on-8-June-change-interface-queries-as-instructed).

## Usage

### Print Code to Download Data from a Table URL

You can use `pxwebtools` to print pxweb query templates and download pxweb data
in more convenient format than directly with `pxweb` package.

First, you can print a query template using `pxw_print_code_full_query_c` 
with a pxweb webpage url or with an api url. A query with all possible levels for
all variables is printed and copied to the clipboard. The URL can be copied
straight from the address bar of the web interface, the view path after the
table file is dropped.

This function generates R code to download a `data.frame` from a PxWeb API using 
a PxWeb web page url to a table or an API url. Code is copied to clipboard.

#### Parameters

- `url`: A PxWeb API URL to the table or a web interface URL.
- `time_all`: If `TRUE` (default), the time variable is set to `c("*")`.


#### Example Usage

```r
library(pxwebtools)

pxw_print_code_full_query_c("https://pxdata.stat.fi/PxWeb/pxweb/en/StatFin/StatFin__tyti/11pk.px/")

```

The printed code is a complete `pxw_get_data` call, with the variable codes and
value codes of the table. The codes come from the table metadata, so you do not
need to know them beforehand. The template has the following shape, where the
time variable and the classification variables are named by their variable
codes:

```r

dat_11pk_px <- pxw_get_data(
  url = "https://pxdata.stat.fi/PxWeb/api/v1/en/StatFin/tyti/11pk.px/",
  query = 
    list("timeperiod_y"=c("*"),
       "sukupuoli_9_20180101"=c("SSS","1","2"),
       "contentscode"=c(
          "Palkansaajat_yht",
          "Jva_kokoaikatyo",
          "Kokoaikatyo_yht"
          )))
          
```

The template can be pasted and modified, for example by dropping the values
that are not needed:

```r

dat_11pk_px <- pxw_get_data(
  url = "https://pxdata.stat.fi/PxWeb/api/v1/en/StatFin/tyti/11pk.px/",
  query = 
    list("timeperiod_y"=c("*"),
       "sukupuoli_9_20180101"=c("SSS"),
       "contentscode"=c(
          "Palkansaajat_yht",
          "Kokoaikatyo_yht"
          )))
```

The resulting `data.frame` has

- a `time` column of class `Date` as the first column, parsed from the time
  variable of the table,
- one factor column for every classification variable of the query, named by
  the variable code and containing the value codes,
- a numeric `values` column as the last column,
- a `codes_names` attribute with the code to label mapping of each variable.

With `to_name = TRUE` a label column (suffix `_name` by default) is added for
each code column.

### Labels of codes in data

The `codes_names` attribute is most easily read with `pxw_codes_names_table`,
which takes the name of a column of the data:

```r
code_table  <- pxw_codes_names_table(dat_11pk_px, "contentscode")
print(code_table)
```

### Queries written before 8 June 2026

Old queries do not have to be rewritten. The old long table URL, the old
variable names and the value codes without a prefix are translated to the
current form:

```r
# Both of these download the same table
dat <- pxw_get_data(
  url = "https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/ton/statfin_ton_pxt_111e.px",
  query = list("Kuukausi" = c("*"),
               "Tiedot" = c("kuol")))

dat <- pxw_get_data(
  url = "https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/ton/111e.px",
  query = list("timeperiod_m" = c("*"),
               "contentscode" = c("ton-kuol")))
```

Note that the columns of the returned data are named after the variable codes
of the table, so code that refers to a column by its old name needs to be
updated.

### Converting PxWeb URLs to API URLs

The `url_web2api()` function converts a PxWeb web interface URL into an API-compatible URL:

```r


# Example 1: StatFin database, with the table file name shortened
web_url <- "https://pxdata.stat.fi/PxWeb/pxweb/fi/StatFin/StatFin__ati/statfin_ati_pxt_11zt.px"
api_url <- url_web2api(web_url)
cat(api_url)
# Output: "https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/ati/11zt.px"

# Example 2: URL copied from the address bar of the web interface
web_url <- "https://pxdata.stat.fi/PxWeb/pxweb/fi/StatFin/StatFin__ton/111e.px/table/tableViewLayout1/"
api_url <- url_web2api(web_url)
cat(api_url)
# Output: "https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/ton/111e.px/"

# Example 3: LUKE database
web_url <- "https://statdb.luke.fi/PxWeb/pxweb/fi/LUKE/LUKE__04%20Metsa__02%20Rakenne%20ja%20tuotanto__06%20Puun%20markkinahakkuut__04%20Vuositilastot/01a_Teollisuuspuun_hakkuut_maak_v.px/"
api_url <- url_web2api(web_url)
cat(api_url)
# Output: "https://statdb.luke.fi/PxWeb/api/v1/fi/LUKE/04%20Metsa/02%20Rakenne%20ja%20tuotanto/06%20Puun%20markkinahakkuut/04%20Vuositilastot/01a_Teollisuuspuun_hakkuut_maak_v.px/"
```

## Tests

The test suite runs the package against recorded API responses that follow the
structure of the current Statistics Finland API, so most of it runs without a
network connection. The tests in `tests/testthat/test-live-api.R` query the
live API and are skipped when it cannot be reached.

```r
devtools::test()
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
