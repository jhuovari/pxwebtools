
test_that("parse_dates correctly parses yearly data", {
  data_y <- data.frame(values = rnorm(10),
                       Vuosi = as.character(2010:2019))

  date_format <- c(Vuosi = "y")
  result <- parse_dates(data_y, date_format)

  # Check if 'time' column is created and properly formatted
  expect_true("time" %in% colnames(result))
  expect_true(all(class(result$time) == "Date"))
  expect_equal(min(result$time), as.Date("2010-01-01"))
  expect_equal(max(result$time), as.Date("2019-01-01"))
})

test_that("parse_dates correctly parses monthly data", {
  data_m <- data.frame(values = rnorm(24),
                       Kuukausi = as.vector(sapply(as.character(2016:2017),
                                                   paste0,
                                                   paste0("M", c(paste0("0", 1:9), as.character(10:12))))))

date_format <- c(Kuukausi = "Ym")  # Year-Month format
result <- parse_dates(data_m, date_format)

# Check if 'time' column is created and properly formatted
expect_true("time" %in% colnames(result))
expect_true(all(class(result$time) == "Date"))
expect_equal(min(result$time), as.Date("2016-01-01"))
expect_equal(max(result$time), as.Date("2017-12-01"))
})

test_that("parse_dates correctly parses quarterly data", {
  data_q <- data.frame(values = rnorm(12),
                       Vuosineljannes = as.vector(sapply(as.character(2016:2018),
                                                         paste0,
                                                         paste0("Q", as.character(1:4)))))

date_format <- c(Vuosineljannes = "Yq")  # Year-Quarter format
result <- parse_dates(data_q, date_format)

# Check if 'time' column is created and properly formatted
expect_true("time" %in% colnames(result))
expect_true(all(class(result$time) == "Date"))
expect_equal(min(result$time), as.Date("2016-01-01"))
expect_equal(max(result$time), as.Date("2018-10-01"))
})

test_that("parse_dates correctly handles NULL input (uses clean_times2)", {
  data_y <- data.frame(values = rnorm(10),
                       Vuosi = as.character(2010:2019))

  result <- parse_dates(data_y, NULL)

  # Assuming clean_times2 correctly parses yearly data
  expect_true("time" %in% colnames(result))
  expect_true(all(class(result$time) == "Date"))
})

test_that("parse_dates stops if columns in date_format are missing", {
  data_y <- data.frame(values = rnorm(10),
                       Year = as.character(2010:2019))  # Wrong column name

  date_format <- c(Vuosi = "y")  # Vuosi is not present in data

  expect_error(parse_dates(data_y, date_format),
               "Some date_format names are not present in the data frame.")
})
