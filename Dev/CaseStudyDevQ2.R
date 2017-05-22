# coding: utf-8
# CaseStudyRQuebec2017
# Authors : David Beauchemin & Samuel Cabral Cruz

#### Question 2 #####
# Distance calculation function between two airports.
# install.packages("geosphere")
library(geosphere)

airportsDist <- function(sourceIATA,destIATA)
{
  # Verification of the sourceIATA and destIATA
  sourceFindIndex <- match(sourceIATA,airportsCanada$IATA)
  if(is.na(sourceFindIndex))
  {
    stop(paste("sourceIATA :",sourceIATA,"is not a valid IATA code"))
  }
  destFindIndex <- match(destIATA,airportsCanada$IATA)
  if(is.na(destFindIndex))
  {
    stop(paste("destIATA :",destIATA,"is not a valid IATA code"))
  }
  sourceLon <- as.numeric(paste(airportsCanada$longitude))[sourceFindIndex]
  sourceLat <- as.numeric(paste(airportsCanada$latitude))[sourceFindIndex]
  sourceCoord <- c(sourceLon,sourceLat)
  destLon <- as.numeric(paste(airportsCanada$longitude))[destFindIndex]
  destLat <- as.numeric(paste(airportsCanada$latitude))[destFindIndex]
  destCoord <- c(destLon,destLat)
  airportDistList <- list()
  airportDistList$source <- sourceIATA
  airportDistList$dest <- destIATA
  airportDistList$value <- round(distGeo(sourceCoord,destCoord)/1000)
  airportDistList$metric <- "Km"
  airportDistList$xy_dist <- sqrt((sourceLon - destLon)**2 + (sourceLat - destLat)**2)
  airportDistList$sourceIndex <- sourceFindIndex
  airportDistList$destIndex <- destFindIndex
  airportDistList
}
airportsDist("AAA","YQB")
airportsDist("YUL","AAA")
airportsDist("YPA","YQB")
airportsDist("YUL","YQB")
airportsDist("YUL","YQB")$value

# Function to establish the estimated time of arrival
# install.packages("lubridate")
library(lubridate)
arrivalTime <- function(sourceIATA,destIATA)
{
  topSpeed <- 850
  adjustFactor <- list()
  adjustFactor$a <- 0.0001007194 # found by regression (not included)
  adjustFactor$b <- 0.4273381 # found by regression (not included)
  arrivalTimeList <- list()
  arrivalTimeList$source <- sourceIATA
  arrivalTimeList$dest <- destIATA
  arrivalTimeList$departureTime <- Sys.time()
  distance <- airportsDist(sourceIATA,destIATA)
  cruiseSpeed <- (distance$value*adjustFactor$a + adjustFactor$b)*topSpeed
  arrivalTimeList$avgCruiseSpeed <- cruiseSpeed
  arrivalTimeList$flightTime <- ms(round(distance$value/cruiseSpeed*60, digits = 1))
  arrivalTimeList$departureTZ <- paste(airportsCanada[distance$sourceIndex, "tzFormat"])
  arrivalTimeList$arrivalTZ <- paste(airportsCanada[distance$destIndex, "tzFormat"])
  arrivalTimeList$value <- with_tz(arrivalTimeList$departureTime + arrivalTimeList$flightTime, 
                                   tzone = arrivalTimeList$arrivalTZ)
  arrivalTimeList
}
arrivalTime("AAA","YYZ")
arrivalTime("YUL","AAA")
arrivalTime("YUL", "YYZ")
arrivalTime("YUL","YVR")
arrivalTime("YUL", "YYZ")$value
difftime(arrivalTime("YUL", "YVR")$value,Sys.time())
difftime(arrivalTime("YUL", "YYZ")$value,Sys.time())

# Import tax rates by province directly from the web
#install.packages("XML")
#install.packages("RCurl")
#install.packages("rlist")
library(XML)
library(RCurl)
library(rlist)
theurl <- getURL("http://www.calculconversion.com/sales-tax-calculator-hst-gst.html",.opts = list(ssl.verifypeer = FALSE))
tables <- readHTMLTable(theurl)
provinceName <- as.character(sort(unique(airportsCanada$province)))
taxRates <- as.data.frame(cbind(provinceName,as.numeric(sub("%","",tables$`NULL`[-13,5]))/100+1))
colnames(taxRates) <- c("province","taxRate")
taxRates

# Shipping cost calculation function
shippingCost <- function(sourceIATA, destIATA, weight, 
                         percentCredit = 0, dollarCredit = 0)
{
  
  # Verification of the existance of the route between sourceIATA and destIATA
  routeConcat <- as.character(paste(routesCanada$sourceAirport,routesCanada$destinationAirport))
  if(is.na(match(paste(sourceIATA,destIATA),routeConcat)))
  {
    stop(paste("the combination of sourceIATA and destIATA (",sourceIATA,"-",destIATA,") do not corresponds to existing route"))
  }
  
  if(weight < 0 || weight > 30) 
  {
    stop("The weight must be between 0 and 30 Kg")
  }
  
  if(percentCredit < 0 || percentCredit > 1)
  {
    stop("The percentage of credit must be between 0 % and 100 %")
  }
  
  if(dollarCredit < 0)
  {
    stop("The dollar credit must be superior to 0 $")
  }
  
  minimalDist = 100
  distance <- airportsDist(sourceIATA, destIATA)
  if (distance$value < minimalDist)
  {
    # We verify if the distance of shipping is further than the minimal requierement
    stop(paste("The shipping distance is under the minimal requirement of",minDist,"Km"))
  }
  
  # Pricing variables
  distanceFactor <- 0.03
  weightFactor <- 0.8
  fixedCost <- 3.75
  profitMargin <- 1.12
  
  # Trafic Index
  traficIndexSource <- as.numeric(paste(airportsCanada[distance$sourceIndex,"combinedIndex"]))
  traficIndexDest <- as.numeric(paste(airportsCanada[distance$destIndex,"combinedIndex"]))
  
  # Calculation of the base cost
  baseCost <-  fixedCost + (distance$value*distanceFactor + weight*weightFactor)/(traficIndexSource*traficIndexDest)
  
  # Additional automated credits
  automatedCredit <- 1
  # Lightweight
  automatedCredit <-  automatedCredit * ifelse(weight < 2, 0.5, 1)
  # Gold Member
  automatedCredit <-  automatedCredit * ifelse(baseCost > 100, 0.9, 1)
  # Partnership
  automatedCredit <- automatedCredit * switch(sourceIATA,
                                              "YUL" = 0.85,
                                              "YHU" = 0.95,
                                              "YMX" = 0.95,
                                              "YYZ" = 0.9,
                                              "YKZ" = 0.975,
                                              "YTZ" = 0.975,
                                              "YZD" = 0.975)
  # The Migrator
  if(distance$value > 3500)
  {
    automatedCredit <- automatedCredit * 0.8125
  }
  else if(distance$value >= 3000)
  {
    automatedCredit <- automatedCredit * 0.825
  }
  else if(distance$value >= 2500)
  {
    automatedCredit <- automatedCredit * 0.85
  }
  else if(distance$value >= 2000)
  {
    automatedCredit <- automatedCredit * 0.9
  }
  
  # Calculation of taxe rate and control of text
  taxRate <- as.numeric(paste(taxRates[match(airportsCanada[distance$sourceIndex,"province"],taxRates$province),"taxRate"]))
  price <- round(pmax(fixedCost*profitMargin*automatedCredit*taxRate,(baseCost*automatedCredit*profitMargin - dollarCredit)*(1 - percentCredit)*taxRate),2)
  
  # Return List
  shippingCostList <- list()
  shippingCostList$distance <- distance
  shippingCostList$weight <- weight
  shippingCostList$distanceFactor <- distanceFactor
  shippingCostList$weightFactor <- weightFactor
  shippingCostList$fixedCost <- fixedCost
  shippingCostList$profitMargin <- profitMargin
  shippingCostList$percentCredit <- percentCredit
  shippingCostList$dollarCredit <- dollarCredit
  shippingCostList$minimalDist <- minimalDist
  shippingCostList$traficIndex <- list(traficIndexSource,traficIndexDest)
  shippingCostList$baseCost <- baseCost
  shippingCostList$automatedCredit <- 1-automatedCredit
  shippingCostList$taxRate <- taxRate
  shippingCostList$price <- price
  shippingCostList
}
shippingCost("YUL", "YVR", 1)
shippingCost("YUL", "YQB", 1)
shippingCost("YUL", "YVR", 30)
shippingCost("YUL", "YQB", 30)



ftest1 <- function(a,b)
{
  a+b
}
ftest2 <- function(a,b)
{
  return(a)
  a+b
}
ftest1(2,3)
ftest2(2,3)

ftest3 <- function(a=2,b=3)
{
  a+b
}
ftest3()

ftest1(3)
ftest2(3)
ftest2(b=5)
ftest3(3)
ftest3(3,5)
ftest3(b=5)
ftest3(b=5,3)
ftest3(3,5,4)

ftest4 <- function(a,b=3,c,d)
{
  a+b+c+d
}
ftest4(c=2,1,3)

ftest5 <- function(a,b=3,c,d)
{
  returningList <- list()
  returningList$value <- a+b+c+d
  returningList$params <- c(a,b,c,d)
  returningList
}
(x <- ftest5(c=2,1,3,4))
x$value

ftest6 <- function(a,b)
{
  if(b == 0)
  {
    stop("The value of b is not valid. A division by 0 would be generated.")
  }
  a/b
}
ftest6(3,4)
ftest6(3,0)
