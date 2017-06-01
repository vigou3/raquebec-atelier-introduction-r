### RStudio: -*- coding: utf-8 -*-
##
## Copyright (C) 2017 David Beauchemin, Samuel Cabral Cruz, Vincent Goulet
##
## This file is part of the project 
## "Introduction a R - Atelier du colloque R a Quebec 2017"
## http://github.com/vigou3/raquebec-atelier-introduction-r
##
## The creation is made available according to the license
## Attribution-Sharing in the same conditions 4.0
## of Creative Commons International
## http://creativecommons.org/licenses/by-sa/4.0/

#### Question 5 ####
# install.packages("actuar")
library("actuar")

distName <- c("Normal","Gamma","LogNormal","Weibull","Pareto","InvGaussian")
empCDF <- ecdf(compData$weight)
empPDF <- function(x,delta=0.01)
{
  (empCDF(x+delta/2)-empCDF(x-delta/2))/delta
}

#' Statistical distribution adjustment
#' 
#' @param data A vector of value over which we want to fit the distribution
#' @param dist The distribution name
#' @param ... The initial values to be given to the optimisation function
#' @return A list containing : 
#' the optimized parameters, 
#' the error value, 
#' the deviance measure,
#' the convergence indicator and 
#' the number of iterations necessited
#' @examples
#' x <- rnorm(1000,10,2)
#' distFit(x,"Normal", 1, 1)
#' x <- rgamma(1000,5,1)
#' distFit(x,"Gamma", 1, 1)
#' 
distFit <- function(data,dist,...)
{
  dist = tolower(dist)
  args = list(...)
  if(dist == "normal")
  {
    law = "norm"
    nbparam = 2
  }
  else if(dist == "exp")
  {
    law = "exp"
    nbparam = 1
    lower = 0
    upper = 100/mean(data)
  }
  else if(dist == "gamma")
  {
    law = "gamma"
    nbparam = 2
  }
  else if(dist == "lognormal")
  {
    law = "lnorm"
    nbparam = 2
  }
  else if(dist == "weibull")
  {
    law = "weibull"
    nbparam = 2
  }
  else if(dist == "pareto")
  {
    law = "pareto"
    nbparam = 2
  }
  else if(dist == "invgaussian")
  {
    law = "invgauss"
    nbparam = 2
  }
  else if(dist == "student")
  {
    law = "t"
    nbparam = 1
    lower = 0
    upper = 100/mean(data)
  }
  else if(dist == "burr")
  {
    law = "burr"
    nbparam = 3
  }
  else
  {
    message <- "The only distributions available are: 
    Normal, Exp, Gamma, LogNormal, Weibull, Pareto, Student, Burr and InvGaussian.
    (This case will be ignored)"
    stop(message)
  }
  if(nbparam != length(args))
  {
    message <- paste("There is a mismatch between the number of arguments passed to the 
                     function and the number of arguments needed to the distribution.",
                     "The",dist,"distribution is taking",nbparam,"parameters and",
                     length(args),"parameters were given.")
    stop(message)
  }

  # Treament
  if(nbparam == 1)
  {
    param <- optim(par = args, function(par) 
      -sum(do.call(eval(parse(text = paste("d",law,sep=""))),c(list(data),par,log = TRUE))),
      method = "Brent", lower = lower, upper = upper)
  }
  else{
    param <- optim(par = args, function(par) 
      -sum(do.call(eval(parse(text = paste("d",law,sep=""))),c(list(data),par,log = TRUE))))
  }
  # Deviance value
  devValue <- sum((empPDF(x <- seq(0,max(data),0.1))-
                     do.call(eval(parse(text = paste("d",law,sep=""))),c(list(x),param$par)))**2)

  # Return List
  distFitList <- list() 
  distFitList$param <- param$par
  distFitList$errorValue <- param$value
  distFitList$devValue <- devValue
  distFitList$convergence <- param$convergence
  distFitList$nbiter <- param$counts[1]
  distFitList
}

(resultDistFitting <- sapply(distName,function(x) unlist(distFit(compData$weight,x,1,1))))

law <- c("norm","gamma","lnorm","weibull","pareto","invgauss")
col <- c("red", "yellow", "purple", "green", "cyan", "blue")
x <- seq(0,30,0.1)

# Visulization of the goodness of the fit
par(mfrow = c(1,2),font = 2)
plot(function(x) empCDF(x), xlim = c(0,15), main = "", xlab = "weight (Kg)", ylab = "CDF(x)")
invisible(sapply(1:length(law),
                 function(i) curve(do.call(eval(parse(text = paste("p",law[i],sep = ""))),
                                           c(list(x), as.vector(resultDistFitting[c(1:2),i]))), 
                                   add = TRUE, lwd = 3, col = col[i])))
hist(compData$weight, xlim = c(0,15), main = "", xlab = "weight (Kg)", breaks = 300,freq = FALSE)
invisible(sapply(1:length(law),
                 function(i) curve(do.call(eval(parse(text = paste("d",law[i],sep = ""))),
                                           c(list(x), as.vector(resultDistFitting[c(1:2),i]))), 
                                   add = TRUE, lwd = 3, col = col[i])))
legend(x="right", y = "center",distName, inset = 0.1, col = col, pch = 20, pt.cex = 2, cex = 1, 
       ncol = 1, bty = "n", text.width = 2, title = "Distribution")
mtext("Adjustment over Empirical Distribution", side = 3, line = -2, outer = TRUE)

# We thus choose the LogNormal distribution which possesses the smallest deviance and the best fit
distChoice <- "LogNormal"
(paramAdjust <- resultDistFitting[c(1:2),match(distChoice,distName)])

# It is also possible to do the equivalent with fitdistr of the MASS library
library("MASS")
(fit.normal <- fitdistr(compData$weight,"normal"))
(fit.gamma <- fitdistr(compData$weight, "gamma"))
(fit.lognormal <- fitdistr(compData$weight, "lognormal"))
(fit.weibull <- fitdistr(compData$weight, "weibull"))