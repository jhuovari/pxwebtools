#' Print full query from a table URL
#'
#' This function prints the full PxWeb query structure for a given URL.
#'
#' @param url A URL to the table (web interface or API URL).
#' @param time_all If TRUE (default), the time variable is set to \code{c("*")}.
#'
#' @export
#' @examples
#' \dontrun{
#' pxw_print_full_query(url = "https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/ati/11zt.px")
#' pxw_print_full_query(url = "https://pxdata.stat.fi/PxWeb/api/v1/fi/StatFin/tyokay/115u.px")
#' }
pxw_print_full_query <- function(url, time_all = TRUE) {
  # Prepare the full query
  full_query <- pxw_prepare_full_query(url, time_all)

  # pxweb_query_as_rcode() prints as a side effect, capture it and print once.
  utils::capture.output({
    query_text <- pxweb:::pxweb_query_as_rcode(full_query)
  })

  cat(query_text, sep = "\n")
}

#' Print code to download data from a table URL
#'
#' This function generates R code to download a `data.frame` from a PxWeb API using a specified query.
#'
#' The printed query uses the variable codes and value codes of the table
#' metadata, so the generated code is always in the form the API expects. This
#' is the most reliable way to find out the variable codes that Statistics
#' Finland introduced in the 8 June 2026 database change.
#'
#' @param url A PxWeb API URL to the table or a web interface URL.
#' @param time_all If TRUE (default), the time variable is set to \code{c("*")}.
#' @param target A connection, "" to standard output, or "clipboard-128" to copy to the clipboard.
#'
#' @export
#' @examples
#' \dontrun{
#' pxw_print_code_full_query(
#'   url = "https://pxdata.stat.fi/PxWeb/pxweb/fi/StatFin/StatFin__ati/14sk.px"
#' )
#' }
pxw_print_code_full_query <- function(url, time_all = TRUE, target = "") {
  # Convert web URL to API URL if needed
  if (!pxw_is_api_url(url)) {
    url <- url_web2api(url)  # Use url_web2api from pxwebtools
  }
  url <- pxw_normalize_url(url)

  # Prepare the full query
  full_query <- pxw_prepare_full_query(url = url, time_all = time_all)

  suppress_output <-
    utils::capture.output({
      query_text <- pxweb:::pxweb_query_as_rcode(full_query)
    })

  # Generate table code from the URL
  table_code <- gsub("[^a-zA-Z0-9]", "_", basename(url))  # Use table name as code



  # Print R code to download the data
  cat("dat_", table_code, " <- pxw_get_data(\n",
      "  url = \"", url, "\",\n",
      "  query = \n  ",
      paste0(query_text[-1], collapse = "\n"),
      ")",
      sep = "",
      file = target)
}

#' @describeIn pxw_print_code_full_query Print to clipboard
#'
#' @export
pxw_print_code_full_query_c <- function(url, time_all = TRUE, target = "clipboard-128") {
  pxw_print_code_full_query(url = url, time_all = time_all, target = target)
}

#' Prepare a query for printing
#'
#' This function prepares the full query structure for a given PxWeb URL.
#'
#' @param url A URL to the table (web interface or API URL).
#' @param time_all If TRUE (default), the time variable is set to \code{c("*")}.
#'
#' @return A list containing the full PxWeb query structure.
#' @export
pxw_prepare_full_query <- function(url, time_all = TRUE) {
  # Fetch metadata from the PxWeb API
  url <- pxw_normalize_url(url)
  meta <- pxw_pxweb_get(url)

  # Create query with all variables set to "*"
  codes <- sapply(meta$variables, "[[", "code")
  query_list <- as.list(rep("*", times = length(codes)))
  names(query_list) <- codes

  # Create the query
  pxq <- pxweb::pxweb_query(query_list)
  full_query <- pxweb:::pxweb_add_metadata_to_query(pxq, meta)

  # Adjust time variable if needed
  if (time_all) {
    time_codes <- codes[pxw_time_variables(meta)]
    query_codes <- purrr::map_chr(full_query$query, ~ .x$code)
    time_position <- stats::na.omit(match(time_codes, query_codes))
    for (i in time_position) {
      full_query$query[[i]]$selection$values <- "*"
      full_query$query[[i]]$selection$filter <- "all"
    }
  }
  full_query
}

#' Return full query as a list
#'
#' This function evaluates and returns the full query structure as a list.
#'
#' @param url A URL to the table (web interface or API URL).
#' @param time_all If TRUE (default), the time variable is set to \code{c("*")}.
#'
#' @return A list containing the full query.
#' @export
pxw_full_query_as_list <- function(url, time_all = TRUE) {
  # Convert web URL to API URL if needed
  if (!pxw_is_api_url(url)) {
    url <- url_web2api(url)
  }
  url <- pxw_normalize_url(url)

  # Prepare the query and evaluate it as an R object
  utils::capture.output({
    full_query_r_expr <- pxweb:::pxweb_query_as_rcode(
      pxw_prepare_full_query(url, time_all = time_all))
  })
  eval(parse(text = paste0(full_query_r_expr[-1], collapse = "\n")))
}


# Positions of the time variables in PxWeb metadata.
#
# PxWeb metadata flags the time variable with `time = TRUE`. Statistics
# Finland's variable codes for time variables follow the frequency of the
# table (timeperiod_y, timeperiod_q, timeperiod_m) since the 8 June 2026
# database change, and were the variable names (Vuosi, Vuosineljannes,
# Kuukausi) before it. Both are recognised when the metadata does not flag the
# time variable.
pxw_time_variables <- function(meta) {
  variables <- meta$variables
  is_time <- purrr::map_lgl(variables, ~ isTRUE(.x$time))

  if (any(is_time)) {
    return(which(is_time))
  }

  codes <- purrr::map_chr(variables, "code")
  which(pxw_make_names(codes) %in% c("vuosi", "vuosineljannes", "kuukausi") |
          grepl("^timeperiod", codes, ignore.case = TRUE))
}


utils::globalVariables(c("time", "values"))
