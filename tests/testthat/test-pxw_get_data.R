test_that("pxw_get_data fetches and processes data correctly", {
  # Define example URL and query
  url <- "https://statfin.stat.fi/PXWeb/api/v1/fi/StatFin/vkour/statfin_vkour_pxt_12bq.px"
  query <- list("Vuosi" = c("1970", "1975"),
                "Alue" = c("SSS"),
                "Ikä" = c("SSS", "15-19"),
                "Sukupuoli" = c("SSS", "1", "2"),
                "Koulutusaste" = c("SSS", "3T8"),
                "Tiedot" = c("vaesto"))

  # Test basic functionality
  data <- pxw_get_data(url, query)
  expect_s3_class(data, "data.frame")
  expect_true(all(c("time", "values", "alue", "ika") %in% names(data)))

  # Test with full names added
  full_named_data <- pxw_get_data(url, query, to_name = TRUE)
  expect_true(all(c("time", "values", "alue_name", "ika_name") %in% names(full_named_data)))
})

