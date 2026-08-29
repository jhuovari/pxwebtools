# Tests against the live Statistics Finland PxWeb API.
#
# These tests check that the package really works with the API as it is after
# the database change of 8 June 2026. They are skipped on CRAN and whenever the
# API cannot be reached, so that the rest of the test suite can be run without
# a network connection.

statfin_url <- "https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/vkour/12bq.px"
statfin_url_old_style <-
  "https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/vkour/statfin_vkour_pxt_12bq.px"

# A small selection of every variable of the table, to keep the query small.
first_values <- function(query, n = 2) {
  lapply(query, function(values) utils::head(values, n))
}

test_that("live: query template uses the current variable codes", {
  skip_if_no_pxweb_api(statfin_url)

  query <- pxw_full_query_as_list(statfin_url, time_all = FALSE)

  expect_type(query, "list")
  expect_true(length(query) > 1)
  # Since 8 June 2026 the content variable is contentscode and the time
  # variable follows the frequency of the table.
  expect_true("contentscode" %in% names(query))
  expect_true(any(grepl("^timeperiod", names(query))))
})

test_that("live: time variable is left as '*' with time_all", {
  skip_if_no_pxweb_api(statfin_url)

  query <- pxw_full_query_as_list(statfin_url)
  time_variable <- grep("^timeperiod", names(query), value = TRUE)

  expect_length(time_variable, 1)
  expect_equal(query[[time_variable]], "*")
})

test_that("live: pxw_get_data downloads and tidies data", {
  skip_if_no_pxweb_api(statfin_url)

  query <- first_values(pxw_full_query_as_list(statfin_url, time_all = FALSE))
  dat <- suppressMessages(pxw_get_data(statfin_url, query))

  expect_s3_class(dat, "data.frame")
  expect_s3_class(dat$time, "Date")
  expect_type(dat$values, "double")
  expect_equal(names(dat)[1], "time")
  expect_equal(names(dat)[length(names(dat))], "values")
  expect_false(anyNA(dat$time))
  expect_true(nrow(dat) > 0)

  # The code to label mapping is stored for the variables of the data.
  codes_names <- attr(dat, "codes_names", exact = TRUE)
  expect_true(length(codes_names) > 0)
  expect_true(all(names(codes_names) %in% names(dat)))

  code_table <- pxw_codes_names_table(dat, names(codes_names)[1])
  expect_equal(names(code_table), c("codes", "names"))
})

test_that("live: name columns are added with to_name", {
  skip_if_no_pxweb_api(statfin_url)

  query <- first_values(pxw_full_query_as_list(statfin_url, time_all = FALSE))
  dat <- suppressMessages(pxw_get_data(statfin_url, query, to_name = TRUE))

  expect_true(any(grepl("_name$", names(dat))))
})

test_that("live: queries written before the 2026 change still work", {
  skip_if_no_pxweb_api(statfin_url)

  meta <- pxweb::pxweb_get(statfin_url)

  # Before the change the variable name, not the variable code, was the
  # identifier of the variable in a query. Build such a query from the current
  # metadata and check that the package translates it. Prefixed value codes are
  # covered by the tests in test-query-normalize.R.
  old_style_query <- stats::setNames(
    lapply(meta$variables, function(variable) utils::head(variable$values, 2)),
    vapply(meta$variables, function(variable) variable$text, character(1))
  )

  dat <- suppressMessages(pxw_get_data(statfin_url_old_style, old_style_query))

  expect_s3_class(dat, "data.frame")
  expect_s3_class(dat$time, "Date")
  expect_true(nrow(dat) > 0)
})
