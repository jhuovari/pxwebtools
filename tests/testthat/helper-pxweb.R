# Helpers to run the package against recorded PxWeb API responses.
#
# The fixtures in tests/testthat/fixtures are hand written PxWeb API responses
# that follow the structure Statistics Finland introduced in the database
# change of 8 June 2026: short table file names, a variable code for every
# variable (`contentscode` for the content variable, `timeperiod_y`,
# `timeperiod_q` or `timeperiod_m` for the time variable and the code list
# identifier for classification variables) and prefixed value codes. The
# `statfin_old_*` fixtures use the structure from before the change, so that
# backwards compatibility can be tested as well.
#
# Tests against the live API are in test-live-api.R and are skipped when the
# API is not reachable.

px_fixture <- function(file) {
  jsonlite::fromJSON(testthat::test_path("fixtures", file), simplifyVector = FALSE)
}

px_fixture_metadata <- function(table) {
  pxweb:::pxweb_metadata(px_fixture(paste0(table, "_meta.json")))
}

px_fixture_data <- function(table, url) {
  px_data <- pxweb:::pxweb_data(px_fixture(paste0(table, "_data.json")))
  px_data$pxweb_metadata <- px_fixture_metadata(table)
  px_data$url <- url
  px_data
}

# Replace the API call of the package with a fixture for the duration of a
# test. Returns an environment that records the url and the query the package
# sent to the API.
local_px_fixture_api <- function(table, url = px_fixture_url(table),
                                 env = parent.frame()) {
  calls <- new.env(parent = emptyenv())
  calls$url <- NULL
  calls$query <- NULL

  testthat::local_mocked_bindings(
    pxw_pxweb_get = function(url, query = NULL, ...) {
      calls$url <- url
      if (is.null(query)) {
        return(px_fixture_metadata(table))
      }
      calls$query <- query
      px_fixture_data(table, url)
    },
    .env = env
  )

  calls
}

px_fixture_url <- function(table) {
  paste0("https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/",
         switch(table,
                statfin_ton_111e = "ton/111e.px",
                statfin_vkour_12bq = "vkour/12bq.px",
                statfin_ntp_132h = "ntp/132h.px",
                statfin_old_12bq = "vkour/statfin_vkour_pxt_12bq.px",
                stop("Unknown fixture table: ", table)))
}

# Skip a test when the live PxWeb API cannot be reached.
skip_if_no_pxweb_api <- function(url) {
  testthat::skip_on_cran()
  testthat::skip_if_offline()

  reachable <- tryCatch({
    pxweb::pxweb_get(url)
    TRUE
  }, error = function(e) FALSE)

  if (!reachable) {
    testthat::skip(paste("PxWeb API not reachable:", url))
  }
}
