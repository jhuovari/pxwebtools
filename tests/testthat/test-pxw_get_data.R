# End to end tests of pxw_get_data against recorded API responses that follow
# the structure of the Statistics Finland PxWeb API since 8 June 2026.

test_that("pxw_get_data processes a monthly table of the current API", {
  local_px_fixture_api("statfin_ton_111e")

  dat <- suppressMessages(pxw_get_data(
    url = "https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/ton/111e.px",
    query = list("timeperiod_m" = c("*"),
                 "osallinen" = c("*"),
                 "contentscode" = c("*"))
  ))

  expect_s3_class(dat, "data.frame")
  # Time variable parsed from the timeperiod_m variable code, values last.
  expect_equal(names(dat), c("time", "osallinen", "contentscode", "values"))
  expect_s3_class(dat$time, "Date")
  expect_equal(sort(unique(dat$time)), as.Date(c("2026-01-01", "2026-02-01")))

  # Both content values of the table become rows of the contentscode column.
  expect_equal(levels(dat$contentscode), c("ton-kuol", "ton-loukv"))
  expect_equal(levels(dat$osallinen), c("SSS", "1"))
  expect_equal(nrow(dat), 8)
  expect_type(dat$values, "double")
  expect_equal(sum(dat$values), 108)
})

test_that("pxw_get_data stores code to label mapping of the current API", {
  local_px_fixture_api("statfin_ton_111e")

  dat <- suppressMessages(pxw_get_data(
    url = "https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/ton/111e.px",
    query = list("contentscode" = c("*"))
  ))

  codes_names <- attr(dat, "codes_names", exact = TRUE)
  expect_equal(names(codes_names), c("osallinen", "contentscode"))
  expect_equal(codes_names$contentscode,
               c("ton-kuol" = "Kuolleet", "ton-loukv" = "Loukkaantuneet"))

  expect_equal(pxw_codes_names_table(dat, "contentscode")$codes,
               c("ton-kuol", "ton-loukv"))
})

test_that("pxw_get_data adds name columns of the current API", {
  local_px_fixture_api("statfin_ton_111e")

  dat <- suppressMessages(pxw_get_data(
    url = "https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/ton/111e.px",
    query = list("contentscode" = c("*")),
    to_name = TRUE
  ))

  expect_true(all(c("osallinen_name", "contentscode_name") %in% names(dat)))
  expect_equal(levels(dat$contentscode_name), c("Kuolleet", "Loukkaantuneet"))
})

test_that("pxw_get_data translates a query written before the 2026 change", {
  calls <- local_px_fixture_api("statfin_ton_111e")

  dat <- suppressMessages(pxw_get_data(
    # Table URL and query as they were written before 8 June 2026.
    url = "https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/ton/statfin_ton_pxt_111e.px",
    query = list("Kuukausi" = c("2026M01"),
                 "Osallinen" = c("SSS"),
                 "Tiedot" = c("kuol", "loukv"))
  ))

  # The URL is shortened and the query uses variable and value codes.
  expect_equal(calls$url,
               "https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/ton/111e.px")
  expect_equal(calls$query,
               list(timeperiod_m = "2026M01",
                    osallinen = "SSS",
                    contentscode = c("ton-kuol", "ton-loukv")))
  expect_s3_class(dat, "data.frame")
})

test_that("pxw_get_data processes a yearly table with a code list variable", {
  local_px_fixture_api("statfin_vkour_12bq")

  dat <- suppressMessages(pxw_get_data(
    url = "https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/vkour/12bq.px",
    query = list("timeperiod_y" = c("*"),
                 "kunta_1_20260101" = c("*"),
                 "sukupuoli" = c("*"),
                 "contentscode" = c("vaesto"))
  ))

  expect_equal(names(dat),
               c("time", "kunta_1_20260101", "sukupuoli", "contentscode", "values"))
  expect_equal(sort(unique(dat$time)), as.Date(c("1970-01-01", "1975-01-01")))
  expect_equal(nrow(dat), 12)
  expect_equal(levels(dat$kunta_1_20260101), c("SSS", "091"))
})

test_that("pxw_get_data processes a quarterly table", {
  local_px_fixture_api("statfin_ntp_132h")

  dat <- suppressMessages(pxw_get_data(
    url = "https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/ntp/132h.px",
    query = list("timeperiod_q" = c("*"), "contentscode" = c("*"))
  ))

  expect_equal(dat$time, as.Date(c("2026-01-01", "2026-04-01")))
  expect_equal(levels(dat$contentscode), "ntp-bkt")
})

test_that("pxw_get_data still works with tables of the old structure", {
  calls <- local_px_fixture_api("statfin_old_12bq")

  dat <- suppressMessages(pxw_get_data(
    url = "https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/vkour/statfin_vkour_pxt_12bq.px",
    query = list("Vuosi" = c("*"), "Sukupuoli" = c("*"), "Tiedot" = c("vaesto"))
  ))

  # Nothing to translate, the query is passed on as it is.
  expect_equal(calls$query,
               list(Vuosi = "*", Sukupuoli = "*", Tiedot = "vaesto"))
  expect_equal(names(dat), c("time", "sukupuoli", "tiedot", "values"))
  expect_equal(sort(unique(dat$time)), as.Date(c("1970-01-01", "1975-01-01")))
})

test_that("pxw_get_data prints the update time of the table", {
  local_px_fixture_api("statfin_ton_111e")

  expect_message(
    pxw_get_data(
      url = "https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/ton/111e.px",
      query = list("contentscode" = c("*"))
    ),
    "111e.px"
  )
})
