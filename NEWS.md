# pxwebtools 0.1.7

Support for the Statistics Finland PxWeb database change of 8 June 2026, where
table file names were shortened and every variable got a variable code that
replaced the variable name as the identifier used in API queries.

* Table URLs of the active StatFin database are shortened to the current form,
  so URLs such as `.../StatFin/ton/statfin_ton_pxt_111e.px` keep working.
  The archive database `StatFin_Passiivi` was not changed and is left as it is.
* `url_web2api` drops the view path (for example `/table/tableViewLayout1/`)
  that the web interface adds to the address bar, so table URLs can be copied
  directly from the browser.
* `pxw_get_data` translates queries written before the change: variables given
  by their old name are matched to the variable code of the table and value
  codes to prefixed value codes.
* `parse_dates` recognises the time variable codes `timeperiod_y`,
  `timeperiod_q` and `timeperiod_m`, and still parses the old time variables.
* `time_all` of `pxw_prepare_full_query`, `pxw_print_full_query`,
  `pxw_print_code_full_query` and `pxw_full_query_as_list` finds the time
  variable from the table metadata instead of the variable name.
* `pxw_print_full_query` no longer prints the query twice.
* `pxw_codes_names_table` reads the `codes_names` attribute exactly and lists
  the available variables when a variable is not found.
* Tests run the package against recorded API responses of the current API, and
  tests against the live API are skipped when it is not reachable.

Dependencies

* The package no longer depends on statfitools, and has no `Remotes`, so it
  installs from CRAN packages only. The five helper functions the package used
  from statfitools (`make_names`, `clean_names`, `codes2names`,
  `px_code_name` and `clean_times2`) are now internal functions of pxwebtools.
  They are not exported, so nothing is masked when statfitools is also
  attached, and the output of `pxw_get_data` is unchanged.

# pxwebtools 0.1.5

* `pxw_codes_names_table` to Retrieve Variable Codes and Labels from Attributes of Data

# pxwebtools 0.1.3

* Improvement of`pxw_get_data` including `date_format` argument 


# pxwebtools 0.1.0

* `pxw_print_*` - functions to print download code
* `pxw_get_data` to download data from pxweb database.
