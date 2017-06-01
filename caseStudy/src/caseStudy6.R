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

#### Question 6 ####
theurl <- getURL(paste("file:///",path,"/statement/MarkDown/CaseStudyStatement.html",sep = ""),
                 .opts = list(ssl.verifypeer = FALSE))
tables <- readHTMLTable(theurl)
lambdaTable <- as.data.frame(tables$"NULL")
colnames(lambdaTable) <- c("Month","Avg3yrs")
lambdaTable

# The possible routes are filtered as having a departure from 'YUL' 
# and a distribution is created according to the destination index
simAirportsDests <- routesCanada$destinationAirport[routesCanada$sourceAirport == "YUL"]
simCombinedIndex <- combinedIndex[names(combinedIndex) %in% simAirportsDests]
airportsDensity <- simCombinedIndex/sum(simCombinedIndex)

# Function for the simulation of the shipment prices.
simulShipmentPrice <- function(Arrival,Weight)
{
  ownPrice <- ifelse(is(testSim <- try(shippingCost("YUL",Arrival,Weight)$price,silent = TRUE),
                        "try-error"),NA,testSim)
  distance <- airportsDist("YUL",Arrival)$value
  nd <- as.data.frame(cbind(distance,Weight))
  colnames(nd) <- c("distance","weight")
  compPrice <- predict(compModel,newdata = nd)
  customerChoice <- ifelse(is.na(ownPrice),0,ifelse(ownPrice < compPrice,1,0))
  rbind(Arrival,distance,Weight,ownPrice,compPrice,customerChoice)
}

# Function for the simulation of the shipment parameters, weights and destinations.
simulShipment <- function(simNbShipments)
{
  # Weights are then generated for each of the packages.
  simWeights <- eval(parse(
    text = paste("r",law[match(distChoice,distName)],sep = "")))(simNbShipments,
                                                                 paramAdjust[1],
                                                                 paramAdjust[2])
  # We finally generate a destination for each package (the departure will always be from 'YUL').
  simArrivals <- sample(size = simNbShipments,names(airportsDensity),prob = airportsDensity,
                        replace = TRUE)
  sapply(seq(1,simNbShipments),function(x) simulShipmentPrice(simArrivals[x],simWeights[x]))
}

# Function for overall simulation
simulOverall <-function()
{
  # We generate n observations of the Poisson distribution with param = sum (lambda). 
  # We know from probability notion that the sum of independent Poisson distribution follows 
  # a Poisson distribution with param = sum (lambda).
  simNbShipments <- rpois(1 ,lambda = sum(as.numeric(paste(lambdaTable$Avg3yrs))))
  # We simulate each shipment
  simulShipment(simNbShipments)
}

nsim <- 1
simulResults <- replicate(nsim, simulOverall(),simplify = FALSE)
(marketShareSales <- sapply(1:nsim,function(x) 
  sum(as.numeric(simulResults[[x]][6,]))/length(simulResults[[x]][6,])))
(ownRevenus <- sum(as.numeric(simulResults[[1]][4,])*
                     as.numeric(simulResults[[1]][6,]),na.rm = TRUE))
(compRevenus <- sum(as.numeric(simulResults[[1]][5,])*
                      (1-as.numeric(simulResults[[1]][6,])),na.rm = TRUE))
(marketShareRevenus <- ownRevenus/(ownRevenus+compRevenus))

arrivalSales <- as.character(simulResults[[1]][1,simulResults[[1]][6,]==1]) 
distanceSales <- as.numeric(simulResults[[1]][2,simulResults[[1]][6,]==1])
weightSales <- as.numeric(simulResults[[1]][3,simulResults[[1]][6,]==1])

arrivalComp <- as.character(simulResults[[1]][1,simulResults[[1]][6,]==0]) 
distanceComp <- as.numeric(simulResults[[1]][2,simulResults[[1]][6,]==0])
weightComp <- as.numeric(simulResults[[1]][3,simulResults[[1]][6,]==0])

# Representation of the result
table(arrivalSales)
mean(distanceSales)
table(arrivalComp)
mean(distanceComp)
par(mfrow = c(1,1))
hist(weightSales,freq = FALSE,breaks = 100, xlim = c(0,15), main = 
          "Sales vs Theoretical Weights Distribution", xlab = "weight (Kg)")
curve(do.call(eval(parse(text = paste("d",law[match(distChoice,distName)],sep = ""))),
              c(list(x),as.vector(paramAdjust))),add = TRUE, lwd = 2)
abline(v = v <- exp(paramAdjust[1]+paramAdjust[2]**2/2), lwd = 2)
text(v+0.75,0.3,as.character(round(v,2)))
abline(v = v <- mean(weightSales),col = "red", lwd = 2)
text(v + 0.5,0.3,round(v,2),col = "red")
