% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/meta.R
\name{pxw_codes_names_table}
\alias{pxw_codes_names_table}
\title{Retrieve Variable Codes and Labels from Attributes of Data}
\usage{
pxw_codes_names_table(x, var)
}
\arguments{
\item{x}{A data object (typically returned by \code{pxw_get_data}) that contains a "codes" attribute. This attribute should be a list where each element corresponds to a variable's code-to-label mapping.}

\item{var}{A character string specifying the variable name (or identifier) for which the code and label table is required. The function will look for this variable within the "codes" attribute of \code{x}.}
}
\value{
A \code{data.frame} with two columns:
\item{codes}{A character vector containing the codes (the names of the metadata vector).}
\item{names}{A character vector containing the corresponding descriptive labels.}
}
\description{
This function extracts the codes and corresponding labels for a specified variable
from the metadata attributes of a data object retrieved by \code{pxw_get_data}. The data object is expected to have an attribute named "codes",
which is a list where each element is a named vector. The names of this vector are the actual codes,
while the vector values are the descriptive labels.
}
\details{
The function works by retrieving the metadata stored in the "codes" attribute of the data object. It then
extracts the element corresponding to the provided \code{var}, which should be a named vector where each name is a code and each value is the label.
The resulting data frame makes it easier to inspect or manipulate the mapping between codes and their human-readable names.

If the specified variable is not found in the "codes" attribute, the function may return \code{NULL} or lead to an error depending on how the data object is structured.
}
\examples{
\dontrun{
# Retrieve data from the API with specific query parameters
dat <- pxw_get_data(
  date_format = c(Verokausi = "y-m"),
  url = "https://vero2.stat.fi/PxWeb/api/v1/fi/Vero/Tulorekisteri/trt_040.px/",
  query = list(
    "Verokausi" = c("*"),
    "Verotuskunta" = c("000"),
    "Erä" = c("TRT_TULOT_10"),
    "Ikä" = c("SSS"),
    "Tunnusluvut" = c("Arvo_sum")
  )
)

# Extract the code-label table for the variable "era"
code_table <- pxw_codes_names_table(dat, "era")
print(code_table)
}

}
