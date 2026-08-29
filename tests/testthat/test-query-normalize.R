test_that("pxw_normalize_query maps old variable labels and prefixed content codes", {
  meta <- list(variables = list(
    list(
      code = "timeperiod_m",
      text = "Kuukausi",
      values = c("2026M04")
    ),
    list(
      code = "contentscode",
      text = "Tiedot",
      values = c("konn", "ton-kuol", "ton-loukv")
    )
  ))

  query <- list(
    "Kuukausi" = c("2026M04"),
    "Tiedot" = c("kuol", "ton-loukv")
  )

  expect_equal(
    pxw_normalize_query(query, meta),
    list(
      timeperiod_m = c("2026M04"),
      contentscode = c("ton-kuol", "ton-loukv")
    )
  )
})
