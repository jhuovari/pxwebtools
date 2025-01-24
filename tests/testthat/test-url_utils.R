test_that("url_web2api handles multiple underscores correctly", {
  web_url <- "https://statdb.luke.fi/PxWeb/pxweb/fi/LUKE/LUKE__04%20Metsa__02%20Rakenne%20ja%20tuotanto__06%20Puun%20markkinahakkuut__04%20Vuositilastot/01a_Teollisuuspuun_hakkuut_maak_v.px/"

  expect_equal(
    url_web2api(web_url),
    "https://statdb.luke.fi/PxWeb/api/v1/fi/LUKE/04%20Metsa/02%20Rakenne%20ja%20tuotanto/06%20Puun%20markkinahakkuut/04%20Vuositilastot/01a_Teollisuuspuun_hakkuut_maak_v.px/"
  )
})

test_that("url_web2api removes first prefix and converts other underscores", {
  web_url_statfin <- "https://pxdata.stat.fi/PxWeb/pxweb/fi/StatFin/StatFin__ati/statfin_ati_pxt_11zt.px"

  expect_equal(
    url_web2api(web_url_statfin),
    "https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/ati/statfin_ati_pxt_11zt.px"
  )
})
