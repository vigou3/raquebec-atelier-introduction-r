
#### Question 6 ####

theurl <- getURL("https://raw.githubusercontent.com/vigou3/raquebec-intro/master/Statement/CaseStudyStatement.html",.opts = list(ssl.verifypeer = FALSE) )
tables <- readHTMLTable(theurl)
lambdaTable <- as.data.frame(tables[1], stringsAsFactors = TRUE)
colnames(lambdaTable) <- c("Month","Average")
lambdaTable


simulFunction <- function(nSimul, density, paramDensity, paramWeight, ...)
{
     densityArrival <- as.numeric(as.character(arrivalIndexTable[,2])) / sum(as.numeric(as.character(arrivalIndexTable[,2])))
     density <- tolower(density)
     densityLaw <- switch(density, 
                          poisson = rpois,
                          normale = rnorm,
                          gamma = rgamma,
                          weibull = rweibull,
                          pareto = rpareto,
                          uniforme = runif,
                          lognormale = rlnorm
     )
     shippingYear <- sapply(1:nSimul, function(nSimul) replicate(nSimul, sum(sapply(paramDensity, function(paramDensity) densityLaw(1, paramDensity, ...)))))
     weightSimul <- sapply(1:nSimul, function(k) replicate(shippingYear[k], rlnorm(1, paramWeight[1], paramWeight[2])))
     destIATA <- sapply(1:nSimul, function(k) replicate(shippingYear[k], sample(x = as.character(arrivalIndexTable[,1]), size = 1, prob = densityArrival)))
     price <- matrix(nrow = nSimul, ncol = max(shippingYear))
     for (i in 1:nSimul)
     {
          for (j in 1:shippingYear[i])
          {
               price[i, j] <-  ifelse(is(try(shippingCost("YUL", destIATA[[i]][j], weightSimul[[i]][j]), silent = TRUE), "try-error") == TRUE, NA, shippingCost("YUL", destIATA[[i]][j], weightSimul[[i]][j])$price)
          }
     }
     # Return List
     shippingYearList <- list()
     shippingYearList$density <- density
     shippingYearList$nSimul <- nSimul
     shippingYearList$paramDensity <- paramDensity
     shippingYearList$paramWeight <- paramWeight
     shippingYearList$numberShipYear <- shippingYear
     shippingYearList$weight <- weightSimul
     shippingYearList$desIATA <- destIATA
     shippingYearList$Price <- price
     shippingYearList
}
lnModelsSimul <- simulFunction(2, "poisson", paramDensity = as.numeric(as.character(lambdaTable$Average)), paramWeight = lnModel$par)
lnModelsSimul[[1]][1]

max(lnModelsSimul$Price)

View(lnModelsSimul$Price)
for (i in 1:100){
     restest[i] <- ifelse (is(try(shippingCost("YUL", lnModelsSimul$desIATA[[1]][i], lnModelsSimul$weight[[1]][i] ), silent = TRUE), "try-error") == TRUE,
                           NA, shippingCost("YUL", lnModelsSimul$desIATA[[1]][i], lnModelsSimul$weight[[1]][i] )$price)
}

restest

#alternative
#shippingYear <- replicate(sum(sapply(as.numeric(as.character(lambdaTable$Average)), function(lambda) rpois(1, lambda))), n = nSimul)

# Calcul des prix
priceSimul <- function(modelSimulated)
{
     price <- numeric(modelSimulated$)
     is(try(sapply(1:lnModelsSimul$nSimul, function(simulI) sapply(1:lnModelsSimul$numberShipYear[simulI], 
                                                                   function(parcelJ) shippingCost("YUL", lnModelsSimul$desIATA[[simulI]][parcelJ], lnModelsSimul$weight[[simulI]][parcelJ] ))), silent = TRUE), "try-error")
     
}

is(try(sapply(1:lnModelsSimul$nSimul, function(simulI) sapply(1:lnModelsSimul$numberShipYear[simulI], 
                                                              function(parcelJ) shippingCost("YUL", lnModelsSimul$desIATA[[simulI]][parcelJ], lnModelsSimul$weight[[simulI]][parcelJ] ))),silent = TRUE), "try-error")



f<-function(x)
{
     if(x < 0)
     {
          stop("x must be positive")
     }
     log(x) 
}

test <- try(f(2))
test
is(test,"try-error")

test <- try(f(-2),silent=TRUE)
is(test,"try-error")
test