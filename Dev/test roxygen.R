#' Add together two numbers
#'
#' @param x A number
#' @param y A number
#' @return The sum of \code{x} and \code{y}
#' @examples
#' add(1, 1)
#' add(10, 1)
add <- function(x, y) {
  x + y
}

#install.packages("roxygen2")
library(roxygen2)

#install.packages("devtools")
library(devtools)

devtools::document()
