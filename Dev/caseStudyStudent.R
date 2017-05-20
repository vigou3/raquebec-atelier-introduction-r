# Code source Case Study R à Québec 2017

#### Setting working directory properly ####
getwd()
setwd("..")    # Dont execute two times
(path <- getwd())
set.seed(31459)

#### Question 1 - Extraction, traitement, visualisation et analyse des données ####

# 1.1 - Extraction des bases de données Airports.dat, routes.dat et airlines.dat
airports <- read.csv(paste(path,"/Reference/AirportModif.csv",sep=""), na.strings=c("\\N",""), fileEncoding = "UTF-8", comment = "#")
routesCanada <- read.csv(paste(path,"/Reference/RoutesModif.csv",sep=""),  na.strings=c("\\N",""), fileEncoding = "UTF-8", comment = "#")
province <- read.csv(paste(path,"/Reference/province.csv",sep=""), na.strings=c("\\N",""), fileEncoding = "UTF-8", comment = "#")

# 1.2 - On garde l'informations pour la Canada seulement
airportsCanada <- airports[airports$country=="Canada",]

# 1.3 - Extraire des informations générales sur la distribution des variables présentent dans le jeu de données 
# et vous informer sur la signification de ces dernières ainsi que sur les différentes modalités quelles peuvent 
# prendre

# Voici différente fonction R qui vous permette de visualiser les données
View(airportsCanada)
head(airportsCanada)
summary(airportsCanada)

nbAirportCity <- table(airportsCanada$city) 
(nbAirportCity <- sort(nbAirportCity,decreasing=TRUE))[1:10]

# 1.4 - Corriger les modalités des variables et faire une sélection des variables qui vous semble utiles 
# pour le reste du traitement.
# Filtrer la pertinence des données
# Nous observons que les variables typeAirport et Source ne sont d'aucune utilité dans la situation présente
# compte tenu que nous n'utilisons que l'information sur le transport par voies aériennes.
# De plus, les variables timezone et DST ne sont pas pertinente étant donner que nous avons le tzFormat complet.
# Un raisonnement similaire est applicable pour la variable country qui ne possèdera que la modalité Canada.
airportsCanada <- subset(airportsCanada, select = -c(country, timezone, DST, typeAirport, Source ))

# Comme on l'a vu dans le sumary(), nous n'avons pas l'IATA pour 27 aéroports
airportsCanada[is.na(airportsCanada$IATA),c("airportID","name","IATA","ICAO")]

# Cependant, toutes ces aéroports possèdent un code ICAO bien défini ce qui permettra d'attribuer une valeur
# par défaut. Une autre possibilité aurait été de simplement ignorer ces aéroports dans le reste de l'analyse.
# Cette approximation ne semble pas trop contraignante compte tenu du fait que les trois derniers caractères
# du code ICAO correspondent au code IATA dans 82% des cas.
sum(airportsCanada$IATA==substr(airportsCanada$ICAO,2,4),na.rm = TRUE)/sum(!is.na(airportsCanada$IATA))

# Nous sommes maintenant en mesure de combler les IATA manquante et nous supprimons l'ICAO car il est maintenant inutile
airportsCanada$IATA <- as.character(airportsCanada$IATA) 
airportsCanada$IATA[is.na(airportsCanada$IATA)] <- substr(airportsCanada$ICAO[is.na(airportsCanada$IATA)],2,4) 
airportsCanada$IATA <- as.factor(airportsCanada$IATA)
airportsCanada <- subset(airportsCanada, select = -ICAO)
View(airportsCanada)

# Plus tard, il sera nécessaire d'avoir la province des aéroports pour la tarrification, 
# à l'aide des données sur les provinces on joint les données airportsCanada  et
# province.

# On analyse d'abord les données province
summary(province)

# On remarque qu'il manque 12 provinces, nous allons garder les données et les traiter la situation plus tard.
airportsCanada<- merge(airportsCanada, province, by.x = "IATA", by.y = "IATA", all.x = TRUE, all.y = TRUE, incomparables = NULL)

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
# Nous pouvons ainsi nous débarasser de ces variables
routesCanada <- subset(routesCanada, select = -c(codeshare, stops))
summary(routesCanada)

# 1.5 - Créer une carte affichant les différents aéroports sur une carte du Canada
# install.packages("ggmap")
library(ggmap)
map <- get_map(location = " Canada" , zoom = 3)
lon <- as.numeric(paste(airportsCanada$longitude))
lat <- as.numeric(paste(airportsCanada$latitude))
airportsCoord <- as.data.frame(cbind(lon, lat))
(mapPoints <- ggmap(map) + geom_point(data=airportsCoord,aes(lon,lat),alpha=0.5))

# 1.6 - Créer une seconde carte montrant toutes les routes possibles entre ces différents aéroports
summary(routesCanada)
summary(airportsCanada)

# Ici, on utilise une requête SQL.
# install.packages("sqldf")
library("sqldf")
routesCoord <- sqldf("
                     select 
                     a.sourceAirport, 
                     a.destinationAirport,
                     b.longitude as sourceLon,
                     b.latitude as sourceLat,
                     c.longitude as destLon,
                     c.latitude as destLat
                     from routesCanada a
                     left join airportsCanada b
                     on a.sourceAirport = b.IATA
                     left join airportsCanada c
                     on a.destinationAirport = c.IATA")
lonBeg <- as.numeric(paste(routesCoord$sourceLon))
latBeg <- as.numeric(paste(routesCoord$sourceLat))
lonEnd <- as.numeric(paste(routesCoord$destLon))
latEnd <- as.numeric(paste(routesCoord$destLat))
routesCoord <- as.data.frame(cbind(lonBeg,latBeg,lonEnd,latEnd))
(mapRoutes <- mapPoints + geom_segment(data=routesCoord,aes(x=lonBeg,y=latBeg,xend=lonEnd,yend=latEnd),alpha=0.5))

# 1.7 Calculer un indice d'achalandage des aéroports en fonction de la quantitée de routes en destination
arrivalFlights <- table(routesCanada$destinationAirport)
totalFlights <- 2 * arrivalFlights  # Logiquement, il y autant de vol entrant que sortant
max(totalFlights)
mean(totalFlights)
var(totalFlights)
sd(totalFlights)
head(sort(totalFlights,decreasing = TRUE),n = 30)
totalFlightsCDF <- ecdf(totalFlights)  #Distribution des vols
IATA <- names(totalFlights)   # Nom des aéroports de l'indice

# Tracer l'index
curve(totalFlightsCDF(x-1),from = 0,to = 60,n = 100,
      xlab = "Nombre de routes par aéroport", 
      ylab = "CDF")

# Calculer un indice à partir de la densité précédente
combinedIndex <- round(totalFlights/max(totalFlights),3)
combinedIndexTable <- data.frame(IATA,
                                 as.numeric(paste(totalFlights)),
                                 as.numeric(paste(combinedIndex)))
rownames(combinedIndexTable) <- NULL
colnames(combinedIndexTable) <- c("IATA","totalFlights","combinedIndex")
combinedIndexTable

# On reajoute l'index aux aéroports canadiens appropriés
airportsCanada<- merge(airportsCanada, combinedIndexTable, by.x = "IATA", by.y = "IATA")

# 1.8- Créer des cartes permettant de visualiser ces indices grâce à un graphique à bulles
lon <- as.numeric(paste(airportsCanada$longitude))
lat <- as.numeric(paste(airportsCanada$latitude))
size <- as.numeric(paste(airportsCanada$combinedIndex))
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
     airportDistList$xy_dist <- sqrt((sourceLon - destLon)**2 + (sourceLat - destLat)**2)
     airportDistList$sourceIndex <- sourceFindIndex
     airportDistList$destIndex <- destFindIndex
     airportDistList
}
airportsDist("AAA" ,"YQB" )
airportsDist("YUL" ,"AAA" )
airportsDist("YPA" ,"YQB" )
airportsDist("YUL" ,"YQB" )
airportsDist("YUL" ,"YQB" )$value

# Fonction pour établir l'heure d'arrivée prévue
# install.packages("lubridate")
library(lubridate)
arrivalTime <- function(sourceIATA,destIATA)
{
     topSpeed <- 850
     adjustFactor <- list()
     adjustFactor$a <- 0.0001007194 # Trouvé par régression (non inclus)
     adjustFactor$b <- 0.4273381 # Trouvé par régression (non inclus)
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

# Fonction de calcul des coûts
shippingCost <- function(sourceIATA, destIATA, weight, 
                         percentCredit = 0, dollarCredit = 0)
{
     # vérifions qu'il existe une route entre sourceIATA et destIATA 
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
     distanceFactor <- 0.03
     weightFactor <- 0.8
     fixedCost <- 3.75
     profitMargin <- 1.12
     
     # Indice de trafic de l'aéroport
     traficIndexSource <- as.numeric(paste(airportsCanada[distance$sourceIndex,"combinedIndex"]))
     traficIndexDest <- as.numeric(paste(airportsCanada[distance$destIndex,"combinedIndex"]))
     
     # Calcul du coût de base
     baseCost <-  fixedCost + (distance$value*distanceFactor + weight*weightFactor)/(traficIndexSource*traficIndexDest)
     
     # Crédits automatisés supplémentaires
     automatedCredit <- 1
     # Lightweight
     automatedCredit <-  automatedCredit * ifelse(weight < 2, 0.5, 1)
     # Gold Member
     automatedCredit <-  automatedCredit * ifelse(baseCost > 100, 0.9, 1)
     
     # Rabais par province
     destProvince <- as.character(airportsCanada[match(destIATA, airportsCanada$IATA),]$province)
     automatedCredit <- automatedCredit * switch(destProvince,
                                                 "Quebec" = 0.85,
                                                 "British Columbia" = 0.95,
                                                 "Ontario" = 0.9,
                                                 "Alberta" = 0.975)
     # The Migrator
     if(distance$value <= 2500 & distance$value > 2000)
     {
          automatedCredit <- automatedCredit * 0.85
     }
     else if(distance$value <= 3000 & distance$value > 2500)
     {
          automatedCredit <- automatedCredit * 0.875
     }
     else if(distance$value > 3000)
     {
          automatedCredit <- automatedCredit * 0.9
     }
     
     # Calcul du prix
     price <- round(pmax(fixedCost*profitMargin*automatedCredit,(baseCost*automatedCredit*profitMargin - dollarCredit)*(1 - percentCredit)),2)
     
     # Liste retourné par la fonction
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

# Visulisation de la variable disntace
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

# Linear model
# Hypothèse de modèle sans taxes pour simplification 

profitMargin <- 1.12
compModel <- lm(price/(profitMargin) ~ distance + weight, compData)
summary(compModel)

# Visualisation du modèele de régression
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
# Omis les tests statistiques pour simplification
distChoice <- "LogNormal"
(paramAdjust <- fit.lognormal$estimate[c(1:2)])


#### Question 6 ####
#install.packages("XML")
#install.packages("RCurl")
#install.packages("rlist")
library(XML)
library(RCurl)
library(rlist)
theurl <- getURL(paste("file:///",path,"/Statement/MarkDown/CaseStudyStatement.html",sep=""),.opts = list(ssl.verifypeer = FALSE))
tables <- readHTMLTable(theurl)
lambdaTable <- as.data.frame(tables$"NULL")
colnames(lambdaTable) <- c("Month","Avg3yrs")
lambdaTable

# On filtre les routes possibles à partir de 'YUL' et 
# on crée une distribution en fonction de l'indice de destination
simAirportsDests <- as.character(paste(routesCanada[routesCanada$sourceAirport == "YUL","destinationAirport"]))
simCombinedIndex <- combinedIndex[names(combinedIndex) %in% simAirportsDests]
airportsDensity <- simCombinedIndex/sum(simCombinedIndex)

# Fonction pour la simulation des prix de l'expédition de colis
simulShipmentPrice <- function(Arrival,Weight)
{
     ownPrice <- ifelse(is(testSim <- try(shippingCost("YUL",Arrival,Weight)$price,silent = TRUE),"try-error"),NA,testSim)
     distance <- airportsDist("YUL",Arrival)$value
     nd <- as.data.frame(cbind(distance,Weight))
     colnames(nd) <- c("distance","weight")
     compPrice <- predict(compModel,newdata = nd)
     customerChoice <- ifelse(is.na(ownPrice),0,ifelse(ownPrice < compPrice,1,0))
     rbind(Arrival,distance,Weight,ownPrice,compPrice,customerChoice)
}

# Fonction pour la simulation des paramètres d'expédition de colis
simulShipment <- function(simNbShipments)
{
     # On génère ensuite des poids pour chacun des colis
     simWeights <- eval(parse(text = paste("r",law[match(distChoice,distName)],sep = "")))(simNbShipments,paramAdjust[1],paramAdjust[2])
     # On génère finalement une destination pour chacun des colis (le départ se fera toujours à partir de 'YUL')
     simArrivals <- sample(size = simNbShipments,names(airportsDensity),prob = airportsDensity,replace = TRUE)
     sapply(seq(1,simNbShipments),function(x) simulShipmentPrice(simArrivals[x],simWeights[x]))
}

# Fonction pour la simulation globale
simulOverall <-function()
{
     # On génère n observations de la distribution Poisson avec param = sum(lambda)
     # La somme de distribution poisson indépendantes suit une distribution poisson avec param = sum(lambda)
     simNbShipments <- rpois(1 ,lambda = sum(as.numeric(paste(lambdaTable$Avg3yrs))))
     # On génère les simulations de chaque colis
     simulShipment(simNbShipments)
}

nsim <- 1
simulResults <- replicate(nsim, simulOverall(),simplify = FALSE)
(marketShareSales <- sapply(1:nsim,function(x) sum(as.numeric(simulResults[[x]][6,]))/length(simulResults[[x]][6,])))
(ownRevenus <- sum(as.numeric(simulResults[[1]][4,])*as.numeric(simulResults[[1]][6,]),na.rm = TRUE))
(compRevenus <- sum(as.numeric(simulResults[[1]][5,])*(1-as.numeric(simulResults[[1]][6,])),na.rm = TRUE))
(marketShareRevenus <- ownRevenus/(ownRevenus+compRevenus))

arrivalSales <- as.character(simulResults[[1]][1,simulResults[[1]][6,]==1]) 
distanceSales <- as.numeric(simulResults[[1]][2,simulResults[[1]][6,]==1])
weightSales <- as.numeric(simulResults[[1]][3,simulResults[[1]][6,]==1])

arrivalComp <- as.character(simulResults[[1]][1,simulResults[[1]][6,]==0]) 
distanceComp <- as.numeric(simulResults[[1]][2,simulResults[[1]][6,]==0])
weightComp <- as.numeric(simulResults[[1]][3,simulResults[[1]][6,]==0])

table(arrivalSales)
mean(distanceSales)
table(arrivalComp)
mean(distanceComp)
par(mfrow = c(1,1))
hist(weightSales,freq = FALSE,breaks = 100, xlim = c(0,15), main = "Sales vs Theoretical Weights Distribution", xlab = "weight (Kg)")
curve(do.call(eval(parse(text = paste("d",law[match(distChoice,distName)],sep = ""))),c(list(x),as.vector(paramAdjust))),add = TRUE, lwd = 2)
abline(v = v <- exp(paramAdjust[1]+paramAdjust[2]**2/2), lwd = 2)
text(v+0.75,0.3,as.character(round(v,2)))
abline(v = v <- mean(weightSales),col = "red", lwd = 2)
text(v - 0.75,0.3,round(v,2),col = "red")

