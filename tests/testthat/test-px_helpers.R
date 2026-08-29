# The helpers the package used to call from statfitools are now internal
# functions of pxwebtools. These tests pin their behaviour.

test_that("pxw_make_names makes valid names", {
  expect_equal(pxw_make_names(c("Määrä", "Regional code")),
               c("maara", "regional_code"))
  expect_equal(pxw_make_names("Hello, world!"), "hello_world")
  expect_equal(pxw_make_names("Vuosineljännes"), "vuosineljannes")
  expect_equal(pxw_make_names("Alue", to_lower = FALSE), "Alue")
  expect_equal(pxw_make_names(c("a", "b"), rename_values = TRUE), c("a", "values"))
})

test_that("pxw_make_names keeps the variable codes of the current API", {
  expect_equal(pxw_make_names(c("timeperiod_m", "contentscode", "kunta_1_20260101")),
               c("timeperiod_m", "contentscode", "kunta_1_20260101"))
})

test_that("pxw_make_names renames the levels of a factor", {
  result <- pxw_make_names(factor(c("Ikä", "Ikä", "Alue")))

  expect_s3_class(result, "factor")
  expect_equal(levels(result), c("alue", "ika"))
})

test_that("pxw_clean_names renames the names of an object", {
  x <- data.frame("col 1!" = c(1, 2), "col 2?" = c(2, 4), check.names = FALSE)

  expect_equal(names(pxw_clean_names(x)), c("col_1", "col_2"))
  expect_equal(names(pxw_clean_names(list("Tiedot" = 1))), "tiedot")
})

test_that("pxw_code_name reads the codes and labels of a pxweb_data object", {
  px_data <- px_fixture_data("statfin_ton_111e", px_fixture_url("statfin_ton_111e"))

  codes_names <- pxw_code_name(px_data)

  expect_equal(names(codes_names), c("timeperiod_m", "osallinen", "contentscode"))
  expect_equal(codes_names$contentscode,
               c("ton-kuol" = "Kuolleet", "ton-loukv" = "Loukkaantuneet"))
})

test_that("pxw_codes2names adds label columns", {
  x <- data.frame(a = c("a1", "a2"), b = c("b1", "b2"))
  cn <- list(a = c("a1" = "first", "a2" = "second"),
             b = c("b1" = "other", "b2" = "something"))

  result <- pxw_codes2names(x, cn, code_suffix = "")

  expect_equal(names(result), c("a", "b", "a_name", "b_name"))
  expect_equal(as.character(result$a_name), c("first", "second"))

  # Only the named columns, with the given suffixes.
  result <- pxw_codes2names(x, cn, to_name = "a", name_suffix = "_label",
                            code_suffix = "_identifier")
  expect_equal(names(result), c("a_identifier", "b", "a_label"))
})

test_that("pxw_codes2names passes the data on when there is nothing to name", {
  x <- data.frame(a = c("a1", "a2"))
  cn <- list(a = c("a1" = "first", "a2" = "second"))

  expect_equal(pxw_codes2names(x, cn, to_name = FALSE), x)
  expect_equal(pxw_codes2names(x, cn, to_name = NULL), x)
  expect_equal(pxw_codes2names(x, cn, to_name = "not_a_column"), x)
  expect_error(pxw_codes2names(x, cn, name_suffix = ""), "name_suffix")
})

test_that("pxw_clean_times parses yearly, quarterly and monthly time variables", {
  expect_equal(
    pxw_clean_times(data.frame(Vuosi = c("2010", "2011"), values = c(1, 2)))$time,
    as.Date(c("2010-01-01", "2011-01-01")))
  expect_equal(
    pxw_clean_times(data.frame(Vuosineljannes = c("2016Q1", "2016Q4"), values = c(1, 2)))$time,
    as.Date(c("2016-01-01", "2016-10-01")))
  expect_equal(
    pxw_clean_times(data.frame(Kuukausi = c("2016M01", "2016M12"), values = c(1, 2)))$time,
    as.Date(c("2016-01-01", "2016-12-01")))
})

test_that("pxw_clean_times replaces the time column", {
  result <- pxw_clean_times(data.frame(Kuukausi = c("2016M01"), values = 1))

  expect_equal(names(result), c("values", "time"))
})

test_that("pxw_clean_times takes the time column as an argument", {
  x <- data.frame(timeperiod_m = c("2016M01", "2016M02"), values = c(1, 2))

  expect_equal(pxw_clean_times(x, time_col = "timeperiod_m")$time,
               as.Date(c("2016-01-01", "2016-02-01")))
})

test_that("pxw_clean_times gives an error it can be acted on", {
  expect_error(pxw_clean_times(data.frame(a = 1)), "Time column not automatically found")
  expect_error(pxw_clean_times(data.frame(timeperiod_w = "2016W01"), time_col = "timeperiod_w"),
               "date_format")
  expect_error(pxw_clean_times(1:3), "data.frame")
})
