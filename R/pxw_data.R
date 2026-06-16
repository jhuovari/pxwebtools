#' Get data from PxWeb API and modify output
#'
#' Downloads data from a PxWeb API, processes it into a tidy format,
#' and optionally modifies the output with variable renaming and name columns.
#'
#' This function fetches data from a PxWeb API, processes it into a long-format
#' `data.frame`, rename time columns to `time` as Date-format with
#' \link[statfitools]{clean_times2} and rename all
#' columns with \link[statfitools]{clean_names},
#' and applies optional transformation adding name columns for codes. The resulting data frame also includes
#' additional attributes such as `codes_names` for mapping codes to names.
#'
#'
#' @param url A PxWeb object or URL that can be coerced to a PxWeb object.
#' @param query A JSON string, JSON file, or list object that can be coerced to a `pxweb_query` object.
#' @param to_name Whether to add columns for names. TRUE, FALSE (default), or a vector of variable names.
#' @param name_suffix Suffix to add to name columns. Default is `"_name"`.
#' @param code_suffix Suffix to add to code columns. Default is `""`.
#' @param date_format A time format for \link{parse_dates}.
#'        See also \link[lubridate]{parse_date_time}.
#' @param print_updated Whether to print update time when not in interactive
#'        session. FALSE (defaut) gives message instead.
#'
#' @import pxweb
#' @import dplyr
#' @export
#'
#' @examples
#' url <- "https://statfin.stat.fi/PXWeb/api/v1/fi/StatFin/vkour/statfin_vkour_pxt_12bq.px"
#' query <- list("Vuosi" = c("1970", "1975"),
#'               "Alue" = c("SSS"),
#'               "Ikä" = c("SSS", "15-19"),
#'               "Sukupuoli" = c("SSS", "1", "2"),
#'               "Koulutusaste" = c("SSS", "3T8"),
#'               "Tiedot" = c("vaesto"))
#'
#' data <- pxw_get_data(url, query)
#' data_named <- pxw_get_data(url, query, to_name = TRUE)
pxw_get_data <- function(url, query, to_name = FALSE,
                         name_suffix = "_name", code_suffix = "",
                         date_format = NULL,
                         print_update = FALSE) {

  # Fetch data from PxWeb API. Statistics Finland changed active StatFin
  # tables in June 2026 so that URLs use the short table ID and query
  # variables use VARIABLECODE values instead of translated variable names.
  url <- pxw_normalize_statfin_api_url(url)
  meta <- pxweb::pxweb_get(url = url)
  query <- pxw_normalize_query(query = query, meta = meta)
  px_data <- pxweb::pxweb_get(url = url, query = query)

  # Extract variable codes and names
  codes_names <- statfitools::px_code_name(px_data)


  # # Determine which columns to name
  # if (names == "all") {
  #   to_name <- names(codes_names)
  # } else if (names == "none") {
  #   to_name <- NULL
  # } else {
  #   to_name <- names
  # }

  # Process the PxWeb data into a tidy data frame
  px_df <- as.data.frame(px_data, column.name.type = "code",
                         variable.value.type = "code") %>%
    tidyr::pivot_longer(where(is.numeric),
                        names_to = setdiff(names(codes_names), names(.)),
                        values_to = "values") %>%
    parse_dates(date_format = date_format) %>%
    statfitools::codes2names(codes_names, to_name = to_name,
                             name_suffix = name_suffix,
                             code_suffix = code_suffix) %>%
    dplyr::mutate(across(where(is.character), ~forcats::as_factor(.x))) %>%
    statfitools::clean_names() %>%
    dplyr::relocate(time) %>%
    dplyr::relocate(values, .after = last_col()) %>%
    droplevels()

  # # Add attributes for citation and codes
  # if (requireNamespace("pttdatahaku")){
  #   attributes(px_df)$citation <- pttdatahaku::ptt_capture_citation(px_data)
  # }

  cleaned_names <- unique(gsub(paste0(name_suffix, "|", code_suffix), "", names(px_df)))

  codes_names <- statfitools::clean_names(codes_names)

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



# Normalize query variable names and selected values against PxWeb metadata.
#
# This keeps older user code working with Statistics Finland's 2026 PxWeb
# metadata where variable identifiers changed from labels (for example
# "Tiedot") to VARIABLECODE values (for example "contentscode").
pxw_normalize_query <- function(query, meta) {
  if (!is.list(query) || inherits(query, "pxweb_query")) {
    return(query)
  }

  variables <- meta$variables
  variable_codes <- purrr::map_chr(variables, "code")
  variable_texts <- purrr::map_chr(variables, "text")

  normalized <- purrr::imap(query, function(values, variable_name) {
    variable_index <- match(variable_name, variable_codes)
    if (is.na(variable_index)) {
      variable_index <- match(variable_name, variable_texts)
    }

    if (is.na(variable_index)) {
      return(values)
    }

    variable_values <- variables[[variable_index]]$values
    if (is.null(variable_values) || identical(values, "*") || identical(values, c("*"))) {
      return(values)
    }

    purrr::map_chr(values, function(value) {
      if (value %in% variable_values) {
        return(value)
      }

      suffix_matches <- variable_values[endsWith(variable_values, paste0("-", value))]
      if (length(suffix_matches) == 1) {
        return(suffix_matches)
      }

      value
    })
  })

  names(normalized) <- purrr::map_chr(names(query), function(variable_name) {
    variable_index <- match(variable_name, variable_codes)
    if (is.na(variable_index)) {
      variable_index <- match(variable_name, variable_texts)
    }

    if (is.na(variable_index)) {
      variable_name
    } else {
      variable_codes[[variable_index]]
    }
  })

  normalized
}
