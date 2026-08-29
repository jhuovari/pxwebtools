# Statistics Finland replaced the variable names used as identifiers in API
# queries with variable codes on 8 June 2026, and added a prefix to some value
# codes of classification variables. pxw_normalize_query translates queries
# written before the change.

meta_current <- list(variables = list(
  list(
    code = "timeperiod_m",
    text = "Kuukausi",
    values = c("2026M03", "2026M04")
  ),
  list(
    code = "ton_alue_1_20260101",
    text = "Alue",
    values = c("SSS", "ton_091")
  ),
  list(
    code = "contentscode",
    text = "Tiedot",
    values = c("konn", "ton-kuol", "ton-loukv")
  )
))

test_that("pxw_normalize_query maps old variable labels and prefixed content codes", {
  query <- list(
    "Kuukausi" = c("2026M04"),
    "Tiedot" = c("kuol", "ton-loukv")
  )

  expect_equal(
    pxw_normalize_query(query, meta_current),
    list(
      timeperiod_m = c("2026M04"),
      contentscode = c("ton-kuol", "ton-loukv")
    )
  )
})

test_that("pxw_normalize_query matches prefixes separated by an underscore", {
  expect_equal(
    pxw_normalize_query(list("Alue" = c("SSS", "091")), meta_current),
    list(ton_alue_1_20260101 = c("SSS", "ton_091"))
  )
})

test_that("pxw_normalize_query leaves queries in the current form untouched", {
  query <- list(
    timeperiod_m = c("*"),
    ton_alue_1_20260101 = c("SSS"),
    contentscode = c("ton-kuol")
  )

  expect_equal(pxw_normalize_query(query, meta_current), query)
})

test_that("pxw_normalize_query keeps wildcards and selection expressions", {
  query <- list("Tiedot" = c("*"), "Kuukausi" = c("top(3)"))

  expect_equal(
    pxw_normalize_query(query, meta_current),
    list(contentscode = "*", timeperiod_m = "top(3)")
  )
})

test_that("pxw_normalize_query keeps unknown variables and values", {
  query <- list("Ei_taulukossa" = c("1"), "Tiedot" = c("ei_koodia"))

  expect_equal(
    pxw_normalize_query(query, meta_current),
    list(Ei_taulukossa = "1", contentscode = "ei_koodia")
  )
})

test_that("pxw_normalize_query does not guess between several prefix matches", {
  meta <- list(variables = list(
    list(code = "contentscode", text = "Tiedot",
         values = c("ton-kuol", "kon-kuol"))
  ))

  expect_equal(
    pxw_normalize_query(list("Tiedot" = c("kuol")), meta),
    list(contentscode = "kuol")
  )
})

test_that("pxw_normalize_query accepts numeric selections", {
  meta <- list(variables = list(
    list(code = "timeperiod_y", text = "Vuosi", values = c("2024", "2025"))
  ))

  expect_equal(
    pxw_normalize_query(list("Vuosi" = c(2024, 2025)), meta),
    list(timeperiod_y = c("2024", "2025"))
  )
})

test_that("pxw_normalize_query passes on queries it cannot handle", {
  json_query <- '{"query": [], "response": {"format": "json"}}'
  expect_equal(pxw_normalize_query(json_query, meta_current), json_query)
  expect_equal(pxw_normalize_query(list("2026M04"), meta_current), list("2026M04"))
  expect_equal(pxw_normalize_query(list(a = "1"), list()), list(a = "1"))
})
