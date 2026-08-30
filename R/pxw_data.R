#' Get data from PxWeb API and modify output
#'
#' Downloads data from a PxWeb API, processes it into a tidy format,
#' and optionally modifies the output with variable renaming and name columns.
#'
#' This function fetches data from a PxWeb API, processes it into a long-format
#' `data.frame`, renames the time columns to `time` as Date-format with
#' \link{parse_dates}, renames all columns to syntactically valid names,
#' and applies optional transformation adding name columns for codes. The resulting data frame also includes
#' additional attributes such as `codes_names` for mapping codes to names.
#'
#' @section Statistics Finland API change of 8 June 2026:
#' Statistics Finland shortened the table file names of its active PxWeb
#' databases and gave every variable a variable code that replaced the variable
#' name as the identifier used in API queries. The content variable is now
#' `contentscode`, the time variable `timeperiod_y`, `timeperiod_q` or
#' `timeperiod_m` depending on the frequency of the table, and classification
#' variables use the identifier of the classification code list. Some value
#' codes of classification variables also got a prefix.
#'
#' `pxw_get_data` keeps queries written before the change working: the URL is
#' shortened to the current form, query variables given by their old name are
#' matched to the corresponding variable code and value codes are matched to
#' prefixed value codes of the table. Use [pxw_print_code_full_query_c()] to
#' print a query template with the current codes.
#'
#' @param url A PxWeb object or URL that can be coerced to a PxWeb object.
#' @param query A JSON string, JSON file, or list object that can be coerced to a `pxweb_query` object.
#' @param to_name Whether to add columns for names. TRUE, FALSE (default), or a vector of variable names.
#' @param name_suffix Suffix to add to name columns. Default is `"_name"`.
#' @param code_suffix Suffix to add to code columns. Default is `""`.
#' @param date_format A time format for \link{parse_dates}.
#'        See also \link[lubridate]{parse_date_time}.
#' @param print_update Whether to print update time when not in interactive
#'        session. FALSE (default) gives message instead.
#'
#' @import pxweb
#' @import dplyr
#' @export
#'
#' @examples
#' \dontrun{
#' url <- "https://statfin.stat.fi/PXWeb/api/v1/fi/StatFin/vkour/12bq.px"
#' query <- list("timeperiod_y" = c("1970", "1975"),
#'               "alue" = c("SSS"),
#'               "ika" = c("SSS", "15-19"),
#'               "sukupuoli" = c("SSS", "1", "2"),
#'               "koulutusaste" = c("SSS", "3T8"),
#'               "contentscode" = c("vaesto"))
#'
#' data <- pxw_get_data(url, query)
#' data_named <- pxw_get_data(url, query, to_name = TRUE)
#' }
pxw_get_data <- function(url, query, to_name = FALSE,
                         name_suffix = "_name", code_suffix = "",
                         date_format = NULL,
                         print_update = FALSE) {

  # Fetch data from PxWeb API. Statistics Finland changed active StatFin
  # tables in June 2026 so that URLs use the short table ID and query
  # variables use VARIABLECODE values instead of translated variable names.
  url <- pxw_normalize_url(url)
  meta <- pxw_pxweb_get(url = url)
  query <- pxw_normalize_query(query = query, meta = meta)
  px_data <- pxw_pxweb_get(url = url, query = query)

  # Extract variable codes and names
  codes_names <- pxw_code_name(px_data)


  # Process the PxWeb data into a tidy data frame
  px_df <- as.data.frame(px_data, column.name.type = "code",
                         variable.value.type = "code") %>%
    tidyr::pivot_longer(where(is.numeric),
                        names_to = setdiff(names(codes_names), names(.)),
                        values_to = "values") %>%
    parse_dates(date_format = date_format) %>%
    pxw_codes2names(codes_names, to_name = to_name,
                    name_suffix = name_suffix,
                    code_suffix = code_suffix) %>%
    dplyr::mutate(across(where(is.character), ~forcats::as_factor(.x))) %>%
    pxw_clean_names() %>%
    dplyr::relocate(time) %>%
    dplyr::relocate(values, .after = last_col()) %>%
    droplevels()

  cleaned_names <- unique(gsub(paste0(name_suffix, "|", code_suffix), "", names(px_df)))

  codes_names <- pxw_clean_names(codes_names)

  # Only keep names that exist in codes_names
  valid_names <- intersect(cleaned_names, names(codes_names))

  attributes(px_df)$codes_names <- codes_names[valid_names]

  # Updated info

  update_time <- px_data$metadata[[1]]$updated |>
    lubridate::ymd_hms()
  px_name <- basename(px_data$url)

  if (print_update & !interactive()) {
    cat(px_name, ": ", as.character(update_time), "\n", sep = "")
  } else {
    message(px_name, ": ", update_time)
  }

  # Return the processed data frame
  px_df
}

utils::globalVariables(c("time", "values", "."))


# Thin wrapper around pxweb::pxweb_get.
#
# All API calls of the package go through this function, which makes it
# possible to run the package against recorded API responses in tests.
pxw_pxweb_get <- function(...) {
  pxweb::pxweb_get(...)
}



# Normalize query variable names and selected values against PxWeb metadata.
#
# This keeps older user code working with Statistics Finland's 2026 PxWeb
# metadata where variable identifiers changed from labels (for example
# "Tiedot") to VARIABLECODE values (for example "contentscode") and where some
# value codes of classification variables got a prefix (for example "kuol"
# became "ton-kuol").
pxw_normalize_query <- function(query, meta) {
  if (!is.list(query) || inherits(query, "pxweb_query")) {
    return(query)
  }

  variables <- meta$variables
  if (is.null(variables) || is.null(names(query))) {
    return(query)
  }

  variable_codes <- purrr::map_chr(variables, "code")
  variable_texts <- purrr::map_chr(variables, "text")

  variable_index <- function(variable_name) {
    index <- match(variable_name, variable_codes)
    if (is.na(index)) {
      index <- match(variable_name, variable_texts)
    }
    index
  }

  normalized <- purrr::imap(query, function(values, variable_name) {
    index <- variable_index(variable_name)

    if (is.na(index)) {
      return(values)
    }

    variable_values <- variables[[index]]$values
    if (is.null(variable_values)) {
      return(values)
    }

    purrr::map_chr(as.character(values), pxw_normalize_value,
                   variable_values = variable_values)
  })

  names(normalized) <- purrr::map_chr(names(query), function(variable_name) {
    index <- variable_index(variable_name)

    if (is.na(index)) {
      variable_name
    } else {
      variable_codes[[index]]
    }
  })

  normalized
}

# Match a single selected value to the value codes of the variable.
#
# Values that are known to the table, wildcard selections and PxWeb selection
# expressions are passed through unchanged. A value that is not known is
# matched to a prefixed value code, when exactly one value code ends with it.
pxw_normalize_value <- function(value, variable_values) {
  if (value %in% variable_values || grepl("[*?()]", value)) {
    return(value)
  }

  suffix_matches <- variable_values[endsWith(variable_values, paste0("-", value)) |
                                      endsWith(variable_values, paste0("_", value))]

  if (length(suffix_matches) == 1) {
    return(suffix_matches)
  }

  value
}
