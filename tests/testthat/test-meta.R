
# Test: when the codes_names attribute is missing, expect an error
test_that("throws error when 'codes_names' attribute is missing", {
  # Create a dummy data object without the 'codes_names' attribute
  dummy_data <- data.frame(x = 1:2)

  # Expect an error when trying to access a non-existent attribute
  expect_error(pxw_codes_names_table(dummy_data, "era"))
})

test_that("throws an informative error for an unknown variable", {
  dat <- data.frame(x = 1:2)
  attr(dat, "codes_names") <- list(contentscode = c("ton-kuol" = "Kuolleet"))

  expect_error(pxw_codes_names_table(dat, "tiedot"), "contentscode")
})

test_that("pxw_codes_names_table returns codes and labels", {
  dat <- data.frame(x = 1:2)
  attr(dat, "codes_names") <- list(
    contentscode = c("ton-kuol" = "Kuolleet", "ton-loukv" = "Loukkaantuneet")
  )

  result <- pxw_codes_names_table(dat, "contentscode")

  expect_true(is.data.frame(result))
  expect_equal(names(result), c("codes", "names"))
  expect_equal(result$codes, c("ton-kuol", "ton-loukv"))
  expect_equal(result$names, c("Kuolleet", "Loukkaantuneet"))
})

test_that("pxw_codes_names_table works on data from the current API", {
  local_px_fixture_api("statfin_vkour_12bq")

  dat <- suppressMessages(pxw_get_data(
    url = "https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/vkour/12bq.px",
    query = list("contentscode" = c("vaesto"))
  ))

  result <- pxw_codes_names_table(dat, "kunta_1_20260101")

  expect_equal(result$codes, c("SSS", "091"))
  expect_equal(result$names, c("KOKO MAA", "Helsinki"))
})
