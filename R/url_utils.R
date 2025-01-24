#' Convert PxWeb Web URL to API URL
#'
#' This function converts a PxWeb web interface URL, which includes a language component,
#' to an API URL for programmatic access. The first redundant prefix (e.g., "LUKE__")
#' is removed, while subsequent double underscores (`__`) are replaced with slashes (`/`).
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
#' url_web2api("https://pxdata.stat.fi/PxWeb/pxweb/fi/StatFin/StatFin__ati/statfin_ati_pxt_11zt.px")
#' # Output: "https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/ati/statfin_ati_pxt_11zt.px"
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

  # Ensure the .px extension and path format remain intact
  return(api_url)
}

# Helper function: Fallback for NULL values
`%||%` <- function(a, b) if (!is.null(a)) a else b
