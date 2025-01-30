#' Parse Time Variables into a Unified Date Column
#'
#' This function processes and converts multiple time-related columns (e.g., year, month, day)
#' into a single `Date` column. If no `date_format` is specified, it defaults to
#' `statfitools::clean_times2()` which automatically parses statfin dates.
#'
#' @param df A data frame containing time-related columns.
#' @param date_format A named vector specifying the format of time-related columns.
#'   Names should match column names in `df`, and values should indicate their format:
#'   - `"y"` for year
#'   - `"m"` for month
#'   - `"d"` for day
#'   - `"q"` for quarter. see more from \link[lubridate]{parse_date_time}.
#'   If `NULL`, the function applies `statfitools::clean_times2()`.
#'
#' @return A modified data frame where time-related columns are merged into a single
#'   `Date` column (`time`), which is moved to the first position.
#'
#' @export
#'
#' @examples
#' df <- data.frame(
#'   Vuosi = c(2023, 2022, 2021),
#'   kuukausi = c(1, 12, 6),
#'   values = c(100, 200, 300)
#' )
#'
#' date_format <- c(Vuosi = "y", kuukausi = "m")
#'
#' parse_dates(df, date_format)
#'
#' # Using the default cleaning function for statfi-style date
#' df2 <- data.frame(
#'   Kuukausi = c("2020M01", "2020M02", "2020M03"),
#'   values = c(100, 200, 300)
#' )
#' parse_dates(df2, NULL)
parse_dates <- function(df, date_format = NULL) {

  if (is.null(date_format)) return(statfitools::clean_times2(df))

  # Ensure date_format is named correctly
  if (!all(names(date_format) %in% names(df))) {
    stop("Some date_format names are not present in the data frame.")
  }

  # Create time string based on formats
  time_str <- df %>%
    dplyr::mutate(dplyr::across(dplyr::all_of(names(date_format)), as.character)) %>%
    tidyr::unite("time_combined", tidyr::all_of(names(date_format)), sep = "-", remove = TRUE, na.rm = TRUE)

  # Determine format string for parsing
  format_str <- paste0(date_format, collapse = "-")

  # Parse the combined time column to Date format
  df <- time_str %>%
    dplyr::mutate(time = as.Date(lubridate::parse_date_time(time_combined, format_str))) %>%
    dplyr::select(-time_combined) %>%  # Remove temporary column
    dplyr::relocate(time, .before = dplyr::everything())  # Move time column to the front

  return(df)
}

utils::globalVariables(c("time_combined"))
