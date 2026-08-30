test_that("url_web2api handles multiple underscores correctly", {
  # A database with a multi-level path. Only string handling is tested, the
  # server is never contacted.
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
    "https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/ati/11zt.px"
  )
})

test_that("url_web2api takes the language from the URL or the argument", {
  web_url <- "https://pxdata.stat.fi/PxWeb/pxweb/en/StatFin/StatFin__ati/11zt.px"

  expect_equal(url_web2api(web_url),
               "https://pxdata.stat.fi/PxWeb/api/v1/en/StatFin/ati/11zt.px")
  expect_equal(url_web2api(web_url, language = "fi"),
               "https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/ati/11zt.px")
})

test_that("url_web2api drops the view path of the web interface", {
  web_url <- "https://pxdata.stat.fi/PxWeb/pxweb/fi/StatFin/StatFin__ton/111e.px/table/tableViewLayout1/"

  expect_equal(
    url_web2api(web_url),
    "https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/ton/111e.px/"
  )
})

# The table file names, TABLEID and MATRIX identifiers of the active
# Statistics Finland databases were shortened on 8 June 2026, for example
# statfin_ton_pxt_111e.px became 111e.px.

test_that("url_web2api shortens active StatFin table filenames", {
  web_url_statfin <- "https://pxdata.stat.fi/PxWeb/pxweb/fi/StatFin/StatFin__ton/statfin_ton_pxt_111e.px"

  expect_equal(
    url_web2api(web_url_statfin),
    "https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/ton/111e.px"
  )
})

test_that("StatFin API URLs are shortened to the current table file name", {
  expect_equal(
    pxw_normalize_url("https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/ton/statfin_ton_pxt_111e.px"),
    "https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/ton/111e.px"
  )
  # A trailing slash is kept, as pxweb accepts both forms.
  expect_equal(
    pxw_normalize_url("https://statfin.stat.fi/PXWeb/api/v1/en/StatFin/vkour/statfin_vkour_pxt_12bq.px/"),
    "https://statfin.stat.fi/PXWeb/api/v1/en/StatFin/vkour/12bq.px/"
  )
})

test_that("shortening does not require the table prefix to match the folder", {
  expect_equal(
    pxw_normalize_url("https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/vaerak/statfin_vamuu_pxt_11ll.px"),
    "https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/vaerak/11ll.px"
  )
})

test_that("URLs that are already in the current form are left as they are", {
  url <- "https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/ton/111e.px"
  expect_equal(pxw_normalize_url(url), url)
})

test_that("databases other than StatFin are not shortened", {
  # The archive database StatFin_Passiivi was not changed on 8 June 2026.
  archive_url <- "https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin_Passiivi/vkour/statfin_vkour_pxt_12bq_2023.px"
  expect_equal(pxw_normalize_url(archive_url), archive_url)

  vero_url <- "https://vero2.stat.fi/PxWeb/api/v1/fi/Vero/Tulorekisteri/trt_040.px/"
  expect_equal(pxw_normalize_url(vero_url), vero_url)
})

test_that("pxw_is_api_url separates API URLs from web interface URLs", {
  expect_true(pxw_is_api_url("https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/ton/111e.px"))
  expect_false(pxw_is_api_url("https://pxdata.stat.fi/PxWeb/pxweb/fi/StatFin/StatFin__ton/111e.px"))
})
