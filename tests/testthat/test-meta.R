
# Test: when 'codes' attribute is missing, expect an error
test_that("throws error when 'codes' attribute is missing", {
  # Create a dummy data object without the 'codes' attribute
  dummy_data <- data.frame(x = 1:2)

  # Expect an error when trying to access a non-existent attribute
  expect_error(pxw_codes_names_table(dummy_data, "era"))
})

# Integration test: using pxw_get_data as in the example
test_that("integration test using pxw_get_data example", {
  # Skip this test on CRAN to avoid external dependency
  skip_on_cran()
  # Optionally, skip in non-interactive sessions:
  # skip_if_not(interactive(), "Skipping integration test in non-interactive session")

  # Retrieve data from the API with specific query parameters
  dat <- pxw_get_data(
    date_format = c(Verokausi = "y-m"),
    url = "https://vero2.stat.fi/PxWeb/api/v1/fi/Vero/Tulorekisteri/trt_040.px/",
    query = list(
      "Verokausi" = c("2020M01"),
      "Verotuskunta" = c("000"),
      "Erä" = c("TRT_TULOT_10"),
      "Ikä" = c("SSS"),
      "Tunnusluvut" = c("Arvo_sum")
    )
  ) |>
  suppressWarnings()

  # Verify that the returned data object has a "codes" attribute
  expect_true(!is.null(attr(dat, "codes_names")))

  # Extract the code-label table for variable "era"
  result <- pxw_codes_names_table(dat, "era")

  # Check that the result is a data frame with expected column names.
  expect_true(is.data.frame(result))
  expect_true(all(c("codes", "names") %in% names(result)))
})
