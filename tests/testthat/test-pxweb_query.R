# Query templates are built from the table metadata, so they follow the
# variable codes Statistics Finland introduced on 8 June 2026.

test_that("pxw_full_query_as_list uses the variable codes of the table", {
  local_px_fixture_api("statfin_ton_111e")

  query <- pxw_full_query_as_list(
    "https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/ton/111e.px")

  expect_equal(query,
               list(timeperiod_m = "*",
                    osallinen = c("SSS", "1"),
                    contentscode = c("ton-kuol", "ton-loukv")))
})

test_that("time_all recognises the timeperiod variable codes", {
  local_px_fixture_api("statfin_ton_111e")
  url <- "https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/ton/111e.px"

  # With time_all the time variable is left as "*" instead of listing every
  # time period of the table.
  expect_equal(pxw_full_query_as_list(url)$timeperiod_m, "*")
  expect_equal(pxw_full_query_as_list(url, time_all = FALSE)$timeperiod_m,
               c("2026M01", "2026M02"))
})

test_that("time_all works for quarterly and yearly variable codes", {
  local_px_fixture_api("statfin_ntp_132h")
  expect_equal(
    pxw_full_query_as_list(
      "https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/ntp/132h.px")$timeperiod_q,
    "*")

  local_px_fixture_api("statfin_vkour_12bq")
  expect_equal(
    pxw_full_query_as_list(
      "https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/vkour/12bq.px")$timeperiod_y,
    "*")
})

test_that("time_all still recognises the old time variable names", {
  local_px_fixture_api("statfin_old_12bq")

  query <- pxw_full_query_as_list(
    "https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/vkour/statfin_vkour_pxt_12bq.px")

  expect_equal(query$Vuosi, "*")
  expect_equal(query$Tiedot, "vaesto")
})

test_that("pxw_print_code_full_query prints code for the current API", {
  local_px_fixture_api("statfin_ton_111e")

  code <- utils::capture.output(
    pxw_print_code_full_query(
      # URL copied from the web interface, view path and all.
      "https://pxdata.stat.fi/PxWeb/pxweb/fi/StatFin/StatFin__ton/111e.px/table/tableViewLayout1/"))
  code <- paste(code, collapse = "\n")

  expect_match(code, "url = \"https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/ton/111e.px/\"",
               fixed = TRUE)
  expect_match(code, "\"timeperiod_m\"=c(\"*\")", fixed = TRUE)
  expect_match(code, "\"contentscode\"=c(\"ton-kuol\",\"ton-loukv\")", fixed = TRUE)
  # The printed code is a call to pxw_get_data that can be run as it is.
  expect_match(code, "^dat_111e_px <- pxw_get_data\\(")
})

test_that("pxw_print_code_full_query shortens old style table URLs", {
  local_px_fixture_api("statfin_ton_111e")

  code <- paste(utils::capture.output(
    pxw_print_code_full_query(
      "https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/ton/statfin_ton_pxt_111e.px")),
    collapse = "\n")

  expect_match(code, "StatFin/ton/111e.px", fixed = TRUE)
  expect_false(grepl("statfin_ton_pxt", code, fixed = TRUE))
})

test_that("pxw_print_full_query prints the query only once", {
  local_px_fixture_api("statfin_ton_111e")

  printed <- utils::capture.output(
    pxw_print_full_query("https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/ton/111e.px"))

  expect_equal(sum(printed == "pxweb_query_list <- "), 1)
  expect_match(paste(printed, collapse = "\n"), "\"timeperiod_m\"=c(\"*\")", fixed = TRUE)
})
