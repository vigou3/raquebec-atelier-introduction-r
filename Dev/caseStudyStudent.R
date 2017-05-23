# coding: utf-8
# Code source Case Study R à Québec 2017
# Auteurs: David Beauchemin & Samuel Cabral Cruz


#### Setting working directory properly ####
getwd()
setwd("..")    # Dont execute two times
(path <- getwd())
set.seed(31459)

#### Question 1 - Importation, traitement, visualisation et analyse des données ####

# 1.1 - Importation des bases de données Airports.dat, routes.dat et airlines.dat
airports <- read.csv(paste(path,"/Reference/AirportModif.csv",sep=""), comment = "#",
                     as.is = c(2, 3, 5), na.strings=c("\\N",""), fileEncoding = "UTF-8")
routesCanada <- read.csv(paste(path,"/Reference/RoutesModif.csv",sep=""),  na.strings=c("\\N",""), fileEncoding = "UTF-8", comment = "#")
province <- read.csv(paste(path,"/Reference/province.csv",sep=""), na.strings=c("\\N",""), 
                     as.is = 1, fileEncoding = "UTF-8", comment = "#")

# 1.2 - On garde l'informations pour la Canada seulement
# drop level et subset
airportsCanada <- airports[airports$country=="Canada",]

# 1.3 - Extraire des informations générales sur la distribution des variables présentent dans le jeu de données 
# et vous informer sur la signification de ces dernières ainsi que sur les différentes modalités quelles peuvent 
# prendre

# Voici différente fonction R qui vous permette de visualiser les données
View(airportsCanada)
head(airportsCanada)
str(airportsCanada)
summary(airportsCanada)

# 1.4 - Corriger les modalités des variables et faire une sélection des variables qui vous semble utiles 
# pour le reste du traitement.
# Nous observons que les variables typeAirport et Source ne sont d'aucune utilité dans la situation présente
# compte tenu que nous n'utilisons que l'information sur le transport par voies aériennes.
# De plus, les variables timezone, DST  et tzFormat ne sont pas pertinente à notre situation.
# Un raisonnement similaire est applicable pour la variable country qui ne possèdera que la modalité Canada.
airportsCanada <- subset(airportsCanada, select = -c(country, timezone, DST, tzFormat, typeAirport, Source ))


# Plus tard, il sera nécessaire d'avoir la province des aéroports pour la tarification, 
# à l'aide des données sur les provinces on joint les données airportsCanada  et
# province.

# On analyse d'abord les données sur les provinces
summary(province)

# On remarque qu'il manque 12 provinces, malgré cela nous allons garder les données sans modification.
airportsCanada<- merge(airportsCanada, province, by.x = "IATA", by.y = "IATA")

# Maintenant on s'intéresse aux voies aériennes canadiennes.
summary(routesCanada)
unique(routesCanada$airline)
unique(routesCanada[,c("airline","airlineID")])
unique(routesCanada$airlineID)
routesCanada[is.na(routesCanada$airlineID),]
unique(routesCanada$airlineID)
unique(routesCanada[is.na(routesCanada$airlineID),]$airline)
summary(routesCanada$stops)

# Comme nous pouvons le remarquer, il n'y a que deux vols qui ne sont pas directs,
# Pour des fins de simplification, nous allons considérer tous les vols comme étant 
# des vols directs
# De plus, la notion de codeshare ne sera pas utile compte tenu que la livraison de
# de marchandise peut autant se faire par l'intermédiaire d'agence aérienne que par 
# vol privé.
# Nous pouvons ainsi nous débarrasser de ces variables
routesCanada <- subset(routesCanada, select = -c(codeshare, stops))
summary(routesCanada)

# 1.5 - Créer une carte affichant les différents aéroports sur une carte du Canada
# install.packages("ggmap")
library(ggmap)
map <- get_map(location = " Canada" , zoom = 3)
lon <- airportsCanada$longitude
lat <- airportsCanada$latitude
airportsCoord <- as.data.frame(cbind(lon, lat))
(mapPoints <- ggmap(map) + geom_point(data=airportsCoord,aes(lon,lat),alpha=0.5))

# 1.6 - Créer une seconde carte montrant toutes les routes possibles entre ces différents aéroports
summary(routesCanada)
summary(airportsCanada)

# Carte des routes
# commentaire ...................
load(file = paste(path,"/Reference/RoutesCoord.R",sep=""))
(mapRoutes <- mapPoints + geom_segment(data=routesCoord,aes(x=routesCoord$lonBeg,y=routesCoord$latBeg,
                                                            xend=routesCoord$lonEnd,yend=routesCoord$latEnd),alpha=0.5))

# 1.7 Calculer un indice d'achalandage des aéroports en fonction de la quantitée de routes en destination
arrivalFlights <- table(routesCanada$destinationAirport)
totalFlights <- 2 * arrivalFlights  # Logiquement, il y autant de vol entrant que sortant
max(totalFlights)
head(sort(totalFlights,decreasing = TRUE),n = 30)
# commentaire sur ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
totalFlightsCDF <- ecdf(totalFlights)  #Distribution des vols
IATA <- names(totalFlights)   # Nom des aéroports de l'indice

# on détermine l'indice
combinedIndex <- round(totalFlights/max(totalFlights),3)
combinedIndexTable <- data.frame(IATA,
                                 as.numeric(paste(totalFlights)),
                                 as.numeric(paste(combinedIndex)))
rownames(combinedIndexTable) <- NULL
colnames(combinedIndexTable) <- c("IATA","totalFlights","combinedIndex")
combinedIndexTable

# Tracer l'index
plot(totalFlightsCDF,
      xlab = "Nombre de routes par aéroport", 
      ylab = "CDF")

# On joint les données sur l'achalandage aux aéroports canadiens appropriés
airportsCanada<- merge(airportsCanada, combinedIndexTable, by.x = "IATA", by.y = "IATA")

# 1.8- Créer des cartes permettant de visualiser ces indices grâce à un graphique à bulles
lon <- airportsCanada$longitude
lat <- airportsCanada$latitude
size <- airportsCanada$combinedIndex
airportsCoord <- as.data.frame(cbind(lon, lat, size))
mapPoints <- 
     ggmap(map) + 
     geom_point(data=airportsCoord,aes(x=lon,y=lat,size=size),alpha=0.5,shape=16)
(mapTraffic <-  
          mapPoints + 
          scale_size_continuous(range = c(0, 20),name = "Traffic Index"))


#### Question 2 #####

# Fonction de calcul de distance entre deux aéroports

# install.packages("geosphere")
library(geosphere)
airportsDist <- function(sourceIATA,destIATA)
{
     # vérifions que sourceIATA et destIATA sont des IATA valides
     # Détermine l'existence du vol
     sourceFindIndex <- match(sourceIATA,airportsCanada$IATA)
     if(is.na(sourceFindIndex))
     {
          stop(paste(" sourceIATA :" ,sourceIATA," is not a valid IATA code" ))
     }
     destFindIndex <- match(destIATA,airportsCanada$IATA)
     if(is.na(destFindIndex))
     {
          stop(paste(" destIATA :" ,destIATA," is not a valid IATA code" ))
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
     airportDistList$sourceIndex <- sourceFindIndex    # Correspond à l'indice de l'aéroport source (lignes)
     airportDistList$destIndex <- destFindIndex        # Correspond à l'indice de l'aéroport destination
     airportDistList
}
airportsDist("AAA" ,"YQB" )
airportsDist("YUL" ,"AAA" )
airportsDist("YPA" ,"YQB" )
airportsDist("YUL" ,"YQB" )
airportsDist("YUL" ,"YQB" )$value

# Fonction de calcul des coûts
shippingCost <- function(sourceIATA, destIATA, weight, 
                         percentCredit = 0, dollarCredit = 0)
{
     # Vérifions qu'il existe une route entre sourceIATA et destIATA 
     routeConcat <- as.character(paste(routesCanada$sourceAirport,routesCanada$destinationAirport))
     if(is.na(match(paste(sourceIATA,destIATA),routeConcat)))
     {
          stop(paste(" the combination of sourceIATA and destIATA (" ,sourceIATA," -" ,destIATA," ) do not corresponds to existing route" ))
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
          # Nous vérifions si la distance de livraison est supérieure à l'exigence minimale
          stop(paste("The shipping distance is under the minimal requirement of",minDist,"Km"))
     }
     
     # Variables de tarification
     distanceFactor <- 0.02
     weightFactor <- 0.6
     fixedCost <- 4
     profitMargin <- 1.10
     
     # Indice de trafic de l'aéroport
     # On extrait le traffic Index de la source et de la destination
     # On utilise l'indice de l'aéroport (ligne)
     traficIndexSource <- airportsCanada[distance$sourceIndex,"combinedIndex"]
     traficIndexDest <- airportsCanada[distance$destIndex,"combinedIndex"]
     
     # Calcul du coût de base
     baseCost <-  fixedCost + (distance$value*distanceFactor + weight*weightFactor)/(traficIndexSource*traficIndexDest)
     
     # Rabais sur le prix
     automatedCredit <- 1
     # Lightweight
     automatedCredit <-  automatedCredit * ifelse(weight < 4, 0.5, 1)
     
     # Rabais par province d'arrivée du colis
     destProvince <- as.character(airportsCanada[match(destIATA, airportsCanada$IATA),]$province)
     automatedCredit <- automatedCredit * switch(destProvince,
                                                 "Quebec" = 0.85,
                                                 "British Columbia" = 0.95,
                                                 "Ontario" = 0.9,
                                                 "Alberta" = 0.975)
     
     # The Migrator
     if(distance$value > 3000)
     {
          automatedCredit <- automatedCredit * 0.9
     }
     else if(distance$value <= 3000 & distance$value > 2500)
     {
          automatedCredit <- automatedCredit * 0.8775
     }
     else if(distance$value <= 2500 & distance$value > 2000)
     {
          automatedCredit <- automatedCredit * 0.85
     }
     # Calcul du prix
     price <- round(pmax(fixedCost*profitMargin*automatedCredit,(baseCost*automatedCredit*profitMargin - dollarCredit)*(1 - percentCredit)),2)
     
     # Liste retournée par la fonction
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
     shippingCostList$destProvince <- destProvince
     shippingCostList$automatedCredit <- 1-automatedCredit
     shippingCostList$price <- price
     shippingCostList
}
shippingCost("YUL", "YVR", 1)
shippingCost("YUL", "YQB", 1)
shippingCost("YUL", "YVR", 30)
shippingCost("YUL", "YQB", 30)

#### Question 3 ####
curve(shippingCost("YUL","YQB",x)$price,0.01,50,ylim=c(0,200),
      main="Shipping Price Variation with Weight",xlab="weight (Kg)",
      ylab="price (CND $)",lwd = 2)
curve(shippingCost("YUL","YVR",x)$price,0.01,50,xlab="weight (Kg)",
      ylab="price (CND $)",add=TRUE, col = "red", lwd = 2)
curve(shippingCost("YUL","YYZ",x)$price,0.01,50,xlab="weight (Kg)",
      ylab="price (CND $)",add=TRUE, col = "blue", lwd = 2)
curve(shippingCost("YUL","YYC",x)$price,0.01,50,xlab="weight (Kg)",
      ylab="price (CND $)",add=TRUE, col = "purple", lwd = 2)
text(x=c(45,45,45,45),y=c(50,110,140,175),c("YUL-YYZ","YUL-YQB","YUL-YVR","YUL-YYC"),adj = 0.5,cex = 0.75,font = 2,col = c("blue","black","red","purple"))


#### Question 4 ####
# Import data de la compétition
compData <- read.csv(paste(path,"/Reference/benchmark.csv",sep="" ))
View(compData)
colnames(compData) <- c("weight","distance","price")
summary(compData)

# Visulisation de la variable poids
hist(compData$weight, freq = TRUE, main = "Repartition according to the weight", 
     xlab = "weight (Kg)", col = "cadetblue",breaks = 50)
weightCDF <- ecdf(compData$weight)
curve(weightCDF(x),0,15,ylim = c(0,1),lwd = 2,
      xlab = "weight (Kg)",
      ylab = "Cumulative Distribution Function")

# Visulisation de la variable distance
hist(compData$distance, freq = TRUE, main = "Repartition according to the distance", 
     xlab = "distance (Km)", col = "cadetblue",breaks = 50)
distanceCDF <- ecdf(compData$distance)
curve(distanceCDF(x),0,2500,ylim = c(0,1),lwd = 2,
      xlab = "distance (Km)",
      ylab = "Cumulative Distribution Function")

# Prix en fonction du poids
plot(compData$weight,compData$price,main = "Price according to the weight",
     xlab = "weight (Kg)", ylab = "Price (CAD $)")

# Prix en fonction de la distance
plot(compData$distance,compData$price,main = "Price according to the distance",
     xlab = "distance (Km)", ylab = "Price (CAD $)")

# Prix en fonction du poids et de la distance
# install.packages("rgl")
library(rgl)
plot3d(compData$weight,compData$distance,compData$price)

# Modèle linéaire
# Hypothèse de modèle sans taxes pour simplification 

profitMargin <- 1.12
compModel <- lm(price/(profitMargin) ~ distance + weight, compData)
summary(compModel)

# Visualisation du modèle de régression
par(mfrow=c(2,2))
plot(compModel)


#### Question 5 ####
# install.packages("actuar")
library("actuar")

# Distribution empirique en fonction du poids
empCDF <- ecdf(compData$weight)

# install.packages("MASS")
library("MASS")
(fit.normal <- fitdistr(compData$weight,"normal"))
(fit.gamma <- fitdistr(compData$weight, "gamma"))
(fit.lognormal <- fitdistr(compData$weight, "lognormal"))
(fit.weibull <- fitdistr(compData$weight, "weibull"))

# Paramètres pours les graphiques
distName <- c("Normal","Gamma","LogNormal","Weibull")
col <- c("red", "yellow", "purple", "green", "cyan", "blue")
x <- seq(0,30,0.1)

par(mfrow = c(1,2),font = 2)
plot(function(x) empCDF(x), xlim = c(0,15), main = "", xlab = "weight (Kg)", ylab = "CDF(x)", lwd = 2)
curve(pnorm(x, fit.normal$estimate[1], fit.normal$estimate[2]), x, add = TRUE, col = "red", lwd = 3)
curve(pgamma(x, fit.gamma$estimate[1], fit.gamma$estimate[2]), x, add = TRUE, col = "yellow", lwd = 3)
curve(plnorm(x, fit.lognormal$estimate[1], fit.lognormal$estimate[2]), x, add = TRUE, col = "purple", lwd = 3)
curve(pweibull(x, fit.weibull$estimate[1], fit.weibull$estimate[2]), x, add= TRUE, col = "green", lwd = 3)

hist(compData$weight, xlim = c(0,15), main = "", xlab = "weight (Kg)", breaks = 300,freq = FALSE)
curve(dnorm(x, fit.normal$estimate[1], fit.normal$estimate[2]), x, add = TRUE, col = "red", lwd = 3)
curve(dgamma(x, fit.gamma$estimate[1], fit.gamma$estimate[2]), x, add = TRUE, col = "yellow", lwd = 3)
curve(dlnorm(x, fit.lognormal$estimate[1], fit.lognormal$estimate[2]), x, add = TRUE, col = "purple", lwd = 3)
curve(dweibull(x, fit.weibull$estimate[1], fit.weibull$estimate[2]), x, add= TRUE, col = "green", lwd = 3)
legend(x="left", y = "center",distName, inset = 0.1, col = col, pch = 20, pt.cex = 2, cex = 0.8, ncol = 1, bty = "n", text.width = 2, title = "Distribution")
mtext("Ajustement sur distribution empirique", side = 3, line = -2, outer = TRUE)

# On choisi donc la loi LogNormal qui possède le meilleur ajustement

distChoice <- "LogNormal"
(paramAdjust <- fit.lognormal$estimate[c(1:2)])
