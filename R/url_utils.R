#' Convert PxWeb Web URL to API URL
#'
#' This function converts a PxWeb web interface URL, which includes a language component,
#' to an API URL for programmatic access. The first redundant prefix (e.g., "LUKE__")
#' is removed, while subsequent double underscores (`__`) are replaced with slashes (`/`).
#'
#' Any web interface path after the table file (for example
#' `/table/tableViewLayout1/`) is dropped, so URLs can be copied directly from
#' the browser address bar. For Statistics Finland's StatFin database the table
#' file name is also shortened to the form used since the 8 June 2026 database
#' change, see [pxw_normalize_url()].
#'
#' @param web_url A string containing the web URL of a PxWeb table.
#' @param language Optional language code for the API (default: extracted from the web URL).
#'   If `language` is provided, it overrides the language code in the web URL.
#' @return A string with the corresponding API URL.
#' @examples
#'
#' url_web2api("https://vero2.stat.fi/PXWeb/pxweb/fi/Vero/Vero__Tulorekisteri/trt_010.px/")
#' # Output: "https://vero2.stat.fi/PxWeb/api/v1/fi/Vero/Tulorekisteri/trt_010.px/"
#'
#' url_web2api("https://statdb.luke.fi/PxWeb/pxweb/fi/LUKE/LUKE__04%20Metsa__02%20Rakenne%20ja%20tuotanto__06%20Puun%20markkinahakkuut__04%20Vuositilastot/01a_Teollisuuspuun_hakkuut_maak_v.px/")
#' # Output: "https://statdb.luke.fi/PxWeb/api/v1/fi/LUKE/04%20Metsa/02%20Rakenne%20ja%20tuotanto/06%20Puun%20markkinahakkuut/04%20Vuositilastot/01a_Teollisuuspuun_hakkuut_maak_v.px"
#'
#' url_web2api("https://pxdata.stat.fi/PxWeb/pxweb/fi/StatFin/StatFin__ati/11zt.px")
#' # Output: "https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/ati/11zt.px"
#' @export
url_web2api <- function(web_url, language = NULL) {
  # Extract the language code from the web URL
  extracted_language <- sub(".+/pxweb/([a-z]{2})/.+", "\\1", web_url, ignore.case = TRUE)

  # Use the provided language if specified, otherwise use the extracted one
  language <- language %||% extracted_language

  # Replace the web URL structure with the API structure
  api_url <- sub(
    "https://(.+?)/[pP][xX][wW]eb/pxweb/[a-z]{2}/",
    sprintf("https://\\1/PxWeb/api/v1/%s/", language),
    web_url
  )

  # Remove the first prefix before "__"
  api_url <- sub("([^/]+?)__", "", api_url)

  # Convert all remaining "__" to "/"
  api_url <- gsub("__", "/", api_url, fixed = TRUE)

  # Drop web interface path elements and apply Statistics Finland's 2026
  # StatFin table file name shortening.
  pxw_normalize_url(api_url)
}

#' Normalize a PxWeb API URL
#'
#' Removes web interface path elements that follow the px table file and
#' shortens Statistics Finland StatFin table file names to the form introduced
#' in the 8 June 2026 PxWeb database change.
#'
#' Statistics Finland shortened the file name, `TABLEID` and `MATRIX`
#' identifiers of all active databases on 8 June 2026. In StatFin the table
#' file `statfin_ton_pxt_111e.px` became `111e.px`. URLs written before the
#' change are rewritten here so that existing user code keeps working. The
#' StatFin archive database (`StatFin_Passiivi`) was not changed and is left
#' untouched.
#'
#' @param url A PxWeb API URL.
#'
#' @return A normalized API URL.
#'
#' @keywords internal
pxw_normalize_url <- function(url) {
  url <- pxw_strip_web_ui_path(url)
  pxw_normalize_statfin_api_url(url)
}

# Drop everything after the px table file, e.g. "/table/tableViewLayout1/",
# that the PxWeb web interface adds to the address bar.
pxw_strip_web_ui_path <- function(url) {
  sub("(\\.px)/.+$", "\\1/", url, ignore.case = TRUE)
}

# Shorten StatFin table file names after the 8 June 2026 table ID change.
#
# Active StatFin table files changed from names such as
# statfin_ton_pxt_111e.px to the short table ID form 111e.px. The archive
# database StatFin_Passiivi was not changed, and is not matched here.
pxw_normalize_statfin_api_url <- function(url) {
  sub(
    "(/StatFin/[^/]+/)statfin_[A-Za-z0-9]+_pxt_([A-Za-z0-9]+\\.px)(/?)$",
    "\\1\\2\\3",
    url,
    ignore.case = FALSE
  )
}

# Is the URL already an API URL?
pxw_is_api_url <- function(url) {
  grepl("/api/v[0-9]+/", url, ignore.case = TRUE)
}

# Helper function: Fallback for NULL values
`%||%` <- function(a, b) if (!is.null(a)) a else b
