#' Parse Time Variables into a Unified Date Column
#'
#' This function processes and converts multiple time-related columns (e.g., year, month, day)
#' into a single `Date` column. If no `date_format` is specified, the format is
#' inferred from the PxWeb time variable code (see Details) and, failing that,
#' `statfitools::clean_times2()` is used to parse statfin dates.
#'
#' @param df A data frame containing time-related columns.
#' @param date_format A named vector specifying the format of time-related columns.
#'   Names should match column names in `df`, and values should indicate their format:
#'   - `"y"` for year
#'   - `"m"` for month
#'   - `"d"` for day
#'   - `"q"` for quarter. see more from \link[lubridate]{parse_date_time}.
#'   If `NULL`, the format is inferred from the data.
#'
#' @details
#' Since the Statistics Finland PxWeb database change of 8 June 2026 the time
#' variable of a table is identified by a variable code that follows the
#' frequency of the table: `timeperiod_y` for yearly, `timeperiod_q` for
#' quarterly and `timeperiod_m` for monthly tables. When `date_format` is
#' `NULL` these columns are recognised and parsed. Tables that still use the
#' old time variable names (`Vuosi`, `Vuosineljannes`, `Kuukausi`) are parsed
#' with `statfitools::clean_times2()` as before.
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
#' # Time variable code of a monthly table in the current StatFin API
#' df2 <- data.frame(
#'   timeperiod_m = c("2020M01", "2020M02", "2020M03"),
#'   values = c(100, 200, 300)
#' )
#' parse_dates(df2, NULL)
#'
#' # Using the default cleaning function for an old style statfi date
#' df3 <- data.frame(
#'   Kuukausi = c("2020M01", "2020M02", "2020M03"),
#'   values = c(100, 200, 300)
#' )
#' parse_dates(df3, NULL)
parse_dates <- function(df, date_format = NULL) {

  if (is.null(date_format)) {
    date_format <- pxw_infer_date_format(df)

    if (is.null(date_format)) {
      return(statfitools::clean_times2(df, time_col = pxw_timeperiod_column(df)))
    }
  }

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


# Formats of the Statistics Finland time variable codes introduced in the
# 8 June 2026 database change. The suffix of the variable code follows the
# frequency of the table.
pxw_timeperiod_formats <- c(y = "y", q = "Yq", m = "Ym")

# Name of the timeperiod column, or NULL when the data has none.
pxw_timeperiod_column <- function(df) {
  timeperiod_columns <- grep("^timeperiod(_[A-Za-z0-9]+)?$", names(df),
                             value = TRUE, ignore.case = TRUE)

  if (length(timeperiod_columns) == 0) {
    return(NULL)
  }

  timeperiod_columns[[1]]
}

# Infer date format for the Statistics Finland timeperiod time variable codes.
# Returns NULL for data without a timeperiod column and for frequencies without
# a known format, which are left to statfitools::clean_times2().
pxw_infer_date_format <- function(df) {
  timeperiod_column <- pxw_timeperiod_column(df)

  if (is.null(timeperiod_column)) {
    return(NULL)
  }

  frequency <- tolower(sub("^timeperiod_?", "", timeperiod_column, ignore.case = TRUE))
  date_format <- pxw_timeperiod_formats[frequency]

  if (is.na(date_format)) {
    return(NULL)
  }

  stats::setNames(unname(date_format), timeperiod_column)
}
