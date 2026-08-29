# Helper functions for PxWeb data.
#
# These are the functions the package used to call from statfitools
# (https://github.com/pttry/statfitools): make_names, clean_names,
# codes2names, px_code_name and clean_times2. They are kept here as internal
# functions so that pxwebtools has no dependency on a package that is only
# available from GitHub, and so that the parsing of Statistics Finland data can
# be developed together with the rest of the package.
#
# The functions are not exported. Use statfitools when you need them directly.
#
# statfitools is licensed under GPL-3 and pxwebtools under MIT. The functions
# below are the work of Janne Huovari, the author of both packages, and are
# licensed here under the MIT license of pxwebtools by their author.


# Make syntactically valid names.
#
# Replaces umlaut characters with a similar character without the mark,
# replaces spaces and punctuation with "_", removes duplicated, leading and
# trailing "_" and finishes with make.names().
pxw_make_names <- function(x, to_lower = TRUE, rename_values = FALSE, ...) {

  if (is.factor(x)) {
    levels(x) <- pxw_make_names(levels(x))
    return(x)
  }

  patt <- c("\u00C4", "\u00E4", "\u00D6", "\u00F6", "\u00C5", "\u00E5", " ")
  repl <- c("A", "a", "O", "o", "A", "a", "_")

  # more general could be iconv(x, to = "ASCII//TRANSLIT"), but TRANSLIT could
  # produce extra characters

  for (i in seq_along(patt)) {
    x <- gsub(patt[i], repl[i], x)
  }

  # remove punctuations
  x <- gsub("[[:punct:]]", "_", x)
  # extra _
  x <- gsub("_+", "_", x)
  x <- gsub("^_|_$", "", x)

  x <- make.names(x, ...)

  if (to_lower) x <- tolower(x)
  if (rename_values) x[length(x)] <- "values"

  x
}


# Apply pxw_make_names() to the names of an object and return the object.
pxw_clean_names <- function(x, to_lower = TRUE, rename_values = FALSE) {
  names(x) <- pxw_make_names(names(x), to_lower = to_lower,
                             rename_values = rename_values, unique = TRUE)
  x
}


# Get the code to label mapping of the variables of a pxweb_data object.
#
# Returns a list named by the variable codes, where each element is a vector of
# labels named by the value codes.
pxw_code_name <- function(px_data) {
  variables <- px_data$pxweb_metadata$variables
  variables <- stats::setNames(variables, sapply(variables, "[[", "code"))

  purrr::map(variables, ~ stats::setNames(.x$valueTexts, .x$values))
}


# Translate code columns to name columns.
#
# @param .data A data.frame or similar.
# @param codes_names A named (column codes) list of named (codes) vectors
#        (labels), for example from pxw_code_name().
# @param to_name Columns to translate. TRUE for all columns of codes_names,
#        FALSE or NULL for none, or a vector of column names.
# @param name_suffix Suffix of the added label columns.
# @param code_suffix Suffix added to the original code columns.
pxw_codes2names <- function(.data, codes_names, to_name = TRUE,
                            name_suffix = "_name", code_suffix = "_code") {

  if (is.null(to_name)) return(.data)

  if (is.character(to_name)) {
    to_name <- to_name
  } else if (isTRUE(to_name)) {
    to_name <- intersect(names(codes_names), names(.data))  # Only keep columns that exist in data
  } else if (isFALSE(to_name)) {
    return(.data)
  }

  if (name_suffix == "") stop("name_suffix cannot be empty")

  # Ensure to_name only includes columns that exist in .data
  valid_to_name <- intersect(to_name, names(.data))

  # Ensure codes_names only includes keys present in .data
  valid_codes_names <- codes_names[names(codes_names) %in% valid_to_name]

  if (length(valid_to_name) == 0) return(.data)  # If no valid columns, return unchanged

  # Add name columns with the specified suffix
  .data <- dplyr::mutate(
    .data,
    across(
      any_of(valid_to_name) & (where(is.character) | where(is.factor)),
      ~ factor(
        .x,
        levels = names(valid_codes_names[[cur_column()]]),
        labels = valid_codes_names[[cur_column()]]
      ),
      .names = paste0("{.col}", name_suffix)
    )
  )

  # Rename original code columns with the specified suffix
  if (code_suffix != "") {
    .data <- dplyr::rename_with(
      .data,
      .cols = any_of(valid_to_name) & (where(is.character) | where(is.factor)),
      ~ paste0(.x, code_suffix)
    )
  }

  # Ensure all code columns are factors
  .data <- dplyr::mutate(
    .data,
    across(
      any_of(paste0(valid_to_name, code_suffix)) & (where(is.character) | where(is.factor)),
      ~ forcats::as_factor(.x)
    )
  )

  .data
}


# Convert a Statistics Finland time variable to a Date column.
#
# The time column is found by name when time_col is NULL, and the frequency
# from the value of the variable: 2020M01 is monthly, 2020Q1 quarterly and
# 2020 yearly. The time column is replaced by a time column of class Date.
pxw_clean_times <- function(x, time_col = NULL) {

  if (!is.data.frame(x)) stop("Input not data.frame!")

  if (is.null(time_col)) {
    time_col <- stats::na.omit(match(c("vuosi", "vuosineljannes", "kuukausi"),
                                     pxw_make_names(names(x))))
  }
  if (length(time_col) == 0) {
    stop("Time column not automatically found. Please assign time column to time_col.")
  }

  freq <- substring(x[1, time_col], 5, 5)
  sub_year_col <- substring(x[1, time_col], 6, 7)

  if (nchar(paste(sub_year_col, collapse = "")) == 0) {
    year_col <- substring(x[[time_col]], 1, 4)
    x$time <- as.Date(paste0(as.character(year_col), "-01-01"))
    x[[time_col]] <- NULL
    return(x)
  }

  if (freq == "M") {
    time <- lubridate::ym(x[[time_col]])
  } else if (freq == "Q") {
    time <- lubridate::yq(x[[time_col]])
  } else {
    stop("Only yearly, quarterly and monthly time variables are parsed. ",
         "Please use the date_format argument.")
  }

  x$time <- time
  x[[time_col]] <- NULL
  x
}
