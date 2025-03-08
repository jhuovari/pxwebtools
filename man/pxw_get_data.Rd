% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/pxw_data.R
\name{pxw_get_data}
\alias{pxw_get_data}
\title{Get data from PxWeb API and modify output}
\usage{
pxw_get_data(
  url,
  query,
  to_name = FALSE,
  name_suffix = "_name",
  code_suffix = "",
  date_format = NULL
)
}
\arguments{
\item{url}{A PxWeb object or URL that can be coerced to a PxWeb object.}

\item{query}{A JSON string, JSON file, or list object that can be coerced to a \code{pxweb_query} object.}

\item{to_name}{Whether to add columns for names. TRUE, FALSE (default), or a vector of variable names.}

\item{name_suffix}{Suffix to add to name columns. Default is \code{"_name"}.}

\item{code_suffix}{Suffix to add to code columns. Default is \code{""}.}

\item{date_format}{A time format for \link{parse_dates}.
See also \link[lubridate]{parse_date_time}.}
}
\description{
Downloads data from a PxWeb API, processes it into a tidy format,
and optionally modifies the output with variable renaming and name columns.
}
\details{
This function fetches data from a PxWeb API, processes it into a long-format
\code{data.frame}, rename time columns to \code{time} as Date-format with
\link[statfitools]{clean_times2} and rename all
columns with \link[statfitools]{clean_names},
and applies optional transformation adding name columns for codes. The resulting data frame also includes
additional attributes such as \code{codes_names} for mapping codes to names.
}
\examples{
url <- "https://statfin.stat.fi/PXWeb/api/v1/fi/StatFin/vkour/statfin_vkour_pxt_12bq.px"
query <- list("Vuosi" = c("1970", "1975"),
              "Alue" = c("SSS"),
              "Ikä" = c("SSS", "15-19"),
              "Sukupuoli" = c("SSS", "1", "2"),
              "Koulutusaste" = c("SSS", "3T8"),
              "Tiedot" = c("vaesto"))

data <- pxw_get_data(url, query)
data_named <- pxw_get_data(url, query, to_name = TRUE)
}
