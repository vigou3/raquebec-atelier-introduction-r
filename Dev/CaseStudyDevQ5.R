#### Question 5 ####
# install.packages("actuar")
library("actuar")

distName <- c("Normal","Gamma","LogNormal","Weibull","Pareto","InvGaussian")
empCDF <- ecdf(compData$weight)
empPDF <- function(x,delta=0.01)
{
  (empCDF(x)-empCDF(x-delta))/delta
}

distFit <- function(dist,...)
{
  dist = tolower(dist)
  args = list(...)
  if(dist == "normal")
  {
    law = "norm"
    nbparam = 2
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
  else
  {
    message <- "The only distribution available are: 
    Nnormal, Gamma, LogNormal, Weibull, Pareto and InvGaussian.
    (The case is ignored)"
    stop(message)
  }
  if(nbparam != length(args))
  {
    message <- paste("There is a mismatch between the number of arguments passed to the function and the number of arguments needed to the distribution.",
                     "The",dist,"distribution is taking",nbparam,"parameters and",length(args),"parameters were given.")
    stop(message)
  }
  
  # Treament
  param <- optim(par = args, function(par) -sum(do.call(eval(parse(text = paste("d",law,sep=''))),c(list(compData$weight),par,log = TRUE))))
  devValue <- sum((empPDF(x <- seq(0,30,0.1))-do.call(eval(parse(text = paste("d",law,sep=''))),c(list(x),param$par)))**2)
  
  # Return List
  distFitList <- list() 
  distFitList$param <- param$par
  distFitList$errorValue <- param$value
  distFitList$devValue <- devValue
  distFitList
}


(resultDistFitting <- sapply(distName,function(x) unlist(distFit(x,1,1))))

law <- c("norm","gamma","lnorm","weibull","pareto","invgauss")
col <- c("red", "yellow", "purple", "green", "cyan", "blue")
x <- seq(0,30,0.1)

par(mfrow = c(1,2),font = 2)
plot(function(x) empCDF(x), xlim = c(0,15), main = "", xlab = "weight (Kg)", ylab = "CDF(x)")
invisible(sapply(1:length(law),function(i) curve(do.call(eval(parse(text = paste("p",law[i],sep = ''))),c(list(x), as.vector(resultDistFitting[c(1:2),i]))), add = TRUE, lwd = 3, col = col[i])))
hist(compData$weight, xlim = c(0,15), main = "", xlab = "weight (Kg)", breaks = 300,freq = FALSE)
invisible(sapply(1:length(law),function(i) curve(do.call(eval(parse(text = paste("d",law[i],sep = ''))),c(list(x), as.vector(resultDistFitting[c(1:2),i]))), add = TRUE, lwd = 3, col = col[i])))
legend(x="right",distName, inset = 0.1, col = col, pch = 20, pt.cex = 2, cex = 1, ncol = 1, bty = "n", text.width = 2, title = "Distribution")
mtext("Ajustement sur distribution empirique", side = 3, line = -2, outer = TRUE)

# On choisi donc la loi LogNormal qui possède la plus petite déviance et le meilleur ajustement
distChoice <- "LogNormal"
(paramAdjust <- resultDistFitting[c(1:2),match(distChoice,distName)])

# Il est aussi possible de faire l'équivalent avec fitdistr de la library MASS, 
# mais nous sommes toutefois restrient sur la sélection des distributions
library("MASS")
(fit.normal <- fitdistr(compData$weight,"normal"))
(fit.gamma <- fitdistr(compData$weight, "gamma"))
(fit.lognormal <- fitdistr(compData$weight, "lognormal"))
(fit.weibull <- fitdistr(compData$weight, "weibull"))

