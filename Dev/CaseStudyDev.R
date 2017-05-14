# Code source Case Study R à Québec 2017

#### Setting working directory properly ####
setwd('..')
(path <- getwd())
set.seed(31459)

#### Question 1 - Extraction, traitement, visualisation et analyse des données ####
# 1.1 - Extraire les bases de données airports.dat et routes.dat
airports <- read.csv("https://raw.githubusercontent.com/jpatokal/openflights/master/data/airports.dat", header = FALSE, stringsAsFactors = TRUE, na.strings=c('\\N',''))
routes <- read.csv("https://raw.githubusercontent.com/jpatokal/openflights/master/data/routes.dat", header = FALSE, stringsAsFactors = TRUE, na.strings=c('\\N',''))
airlines <- read.csv("https://raw.githubusercontent.com/jpatokal/openflights/master/data/airlines.dat", header = FALSE,  stringsAsFactors = TRUE, na.strings=c('\\N',''))

# 1.2 - Attribuer des noms aux colonnes du jeu de données en vous fiant à l'information disponible sur le site
colnames(airports) <- c("airportID", "name", "city", "country", "IATA", "ICAO",
                        "latitude", "longitude", "altitude", "timezone", "DST",
                        "tzFormat","typeAirport","Source")
colnames(routes) <- c("airline","airlineID","sourceAirport","sourceAirportID",
                      "destinationAirport","destinationAirportID","codeshare",
                      "stops","equipment")
colnames(airlines) <- c("airlineID","name","alias","IATA","ICAO","Callsign","Country","Active")

# 1.3 - Nettoyer le jeu de données en ne conservant que les données relatives au Canada
airportsCanada <- airports[airports$country=='Canada',]

# 1.4 - Extraire des informations générales sur la distribution des variables présentent dans le jeu de données 
# et vous informer sur la signification de ces dernières ainsi que sur les différentes modalités quelles peuvent 
# prendre

#Voici différente fonction R qui vous permette de visualiser les données
View(airportsCanada)
head(airportsCanada)
summary(airportsCanada)
nbAirportCity <- table(as.character(airportsCanada$city))
(nbAirportCity <- sort(nbAirportCity,decreasing=TRUE))[1:10]

#
# Filtrer la pertinence des données
#

# 1.5 - Corriger les modalités des variables et faire une sélection des variables qui vous semble utiles 
# pour le reste du traitement
# Nous observons que les variables typeAirport et Source ne sont d'aucune utilité dans la situation présente
# compte tenu que nous n'utilisons que l'information sur le transport par voies aériennes.
# Un raisonnement similaire est applicable pour la variable country qui ne possèdera que la modalité Canada
airportsCanada <- airportsCanada[,-match(c("country","typeAirport","Source"), colnames(airportsCanada))]

# Nous pouvons aussi constater que 27 aéroports ne possèdent aucun code IATA.
airportsCanada[is.na(airportsCanada$IATA),c("airportID","name","IATA","ICAO")]

# Cependant, toutes ces aéroports possèdent un code ICAO bien défini ce qui permettra d'attribuer une valeur
# par défaut. Une autre possibilité aurait été de simplement ignorer ces aéroports dans le reste de l'analyse.
# Cette approximation ne semble pas trop contraignante compte tenu du fait que les trois derniers caractères
# du code ICAO correspondent au code IATA dans 82% des cas.
sum(airportsCanada$IATA==substr(airportsCanada$ICAO,2,4),na.rm = TRUE)/sum(!is.na(airportsCanada$IATA))

# Nous modifions donc la variable IATA et nous nous débarasserons de la variable ICAO
airportsCanada$IATA <- as.character(airportsCanada$IATA)
airportsCanada$IATA[is.na(airportsCanada$IATA)] <- substr(airportsCanada$ICAO[is.na(airportsCanada$IATA)],2,4)
airportsCanada$IATA <- as.factor(airportsCanada$IATA)
airportsCanada <- airportsCanada[,-match("ICAO",colnames(airportsCanada))]
View(airportsCanada)

# Finalement, nous voyons qu'il semble y avoir une quarantaine d'aéroport pour lesquels nous n'avons pas
# d'information sur le fuseau horaire
missingTZ <- airportsCanada[is.na(airportsCanada$timezone),]

# Puisque les fuseaux horaires ne dépendent que de la position géographique, plusieurs options s'offrent à nous:
# 1) Trouver des aéroports proches de c'est derniers pour en déduire les informations
# 2) Utiliser des outils de cartographie pour retrouver les vrais fuseaux horaires
# Nous utiliserons ici la deuxième option qui peut sembler plus complquée de prime abord, mais qui se révèle
# très simple et beaucoup plus précise lorsque nous avons accès à l'information et aux outils nécessaires

# install.packages("sp")
# install.packages("rgdal")
library(sp)
library(rgdal)
tz_world.shape <- readOGR(dsn=paste(path,"/Reference/tz_world",sep=''),layer="tz_world")
unknown_tz <- airportsCanada[is.na(airportsCanada$tzFormat),c("airportID","name","longitude","latitude")]
sppts <- SpatialPoints(unknown_tz[,c("longitude","latitude")])
proj4string(sppts) <- CRS("+proj=longlat")
sppts <- spTransform(sppts, proj4string(tz_world.shape))
merged_tz <- cbind(unknown_tz,over(sppts,tz_world.shape))

#Nous pouvons aussi remarquer que nous n'avons qu'une information dérivée de la province dans laquelle
#est situé chaque aéroport via la ville. Dans le cas de l'application des taxes qui varie par province,
#il sera donc indispensable de rendre cette donnée plus accessible. Nous procéderons encore une fois via
#des techniques de cartographie afin d'extraire la province en fonction des coordonnées x et y
prov_terr.shape <- readOGR(dsn=paste(path,"/Reference/prov_terr",sep=''),layer="gpr_000b11a_e")
unknown_prov <- airportsCanada[,c("airportID","city","longitude","latitude")]
sppts <- SpatialPoints(unknown_prov[,c("longitude","latitude")])
proj4string(sppts) <- CRS("+proj=longlat")
sppts <- spTransform(sppts, proj4string(prov_terr.shape))
merged_prov <- cbind(airportsCanada,over(sppts,prov_terr.shape))

# install.packages("sqldf")
library(sqldf)
airportsCanada <- sqldf("
  select 
    a.*, 
    coalesce(a.tzFormat,b.TZID) as tzMerged,
    c.PRENAME as provMerged
  from airportsCanada a 
  left join merged_tz b
  on a.airportID = b.airportID
  left join merged_prov c
  on a.airportID = c.airportID
  order by a.airportID")
airportsCanada <- data.frame(as.matrix(airportsCanada),stringsAsFactors = TRUE)

# On retire timezone et DST car les données sont inutiles
# On retire tzFormat car il s'Agit des données incomplet et on le remplace plus tard par tzMerged
# On retire city qui ne sera plus utile puisque nous avons maintenant la province
airportsCanada <- airportsCanada[,-match(c("timezone","DST","tzFormat","city"),colnames(airportsCanada))]
summary(airportsCanada)

# install.packages("plyr")
library(plyr)
airportsCanada <- rename(airportsCanada, c("tzMerged"="tzFormat", "provMerged"="province"))
summary(airportsCanada)

routesCanada <- sqldf("
  select *
  from routes
  where sourceAirportID in (select distinct airportID
                            from airportsCanada)
    and destinationAirportID in (select distinct airportID
                                 from airportsCanada)")
routesCanada  <- data.frame(as.matrix(routesCanada ),stringsAsFactors = TRUE)

# Produira le même résultat
# x <- routesCanada[!is.na(match(routesCanada$sourceAirportID,airportsCanada$airportID)) &
#              !is.na(match(routesCanada$destinationAirportID,airportsCanada$airportID)),]
# routesCanada <- routesCanada[!is.na(match(routesCanada$sourceAirport,airportsCanada$IATA)) &
#                 !is.na(match(routesCanada$destinationAirport,airportsCanada$IATA)),]

summary(routesCanada)
unique(routesCanada$airline)
unique(routesCanada[,c("airline","airlineID")])
unique(routesCanada$airlineID)
summary(airlines)
x <- sqldf("
  select *
  from airlines
  where IATA in (select distinct airline
                 from routesCanada)")
x
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
routesCanada <- routesCanada[,-match(c("codeshare","stops"),colnames(routesCanada))]
summary(routesCanada)

# 1.6 - Créer une carte affichant les différents aéroports sur une carte du Canada
# install.packages("ggmap")
library(ggmap)
map <- get_map(location = 'Canada', zoom = 3)
lon <- as.numeric(paste(airportsCanada$longitude))
lat <- as.numeric(paste(airportsCanada$latitude))
airportsCoord <- as.data.frame(cbind(lon, lat))
mapPoints <- ggmap(map) + geom_point(data=airportsCoord,aes(lon,lat),alpha=0.5)
mapPoints

# 1.7 - Créer une seconde carte montrant toutes les routes possibles entre ces différents aéroports
summary(routesCanada)
summary(airportsCanada)
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
mapRoutes <- mapPoints + geom_segment(data=routesCoord,aes(x=lonBeg,y=latBeg,xend=lonEnd,yend=latEnd),alpha=0.5)
mapRoutes

# 1.8 - Calculer un indice d'achalandage des aéroports en fonction de la quantitée de routes en destination
arrivalFlights <- table(routesCanada$destinationAirport)
max(arrivalFlights)
mean(arrivalFlights)
var(arrivalFlights)
sd(arrivalFlights)
head(sort(arrivalFlights,decreasing = TRUE),n = 30)
arrivalCDF <- ecdf(arrivalFlights)
arrivalIndex <- format(arrivalCDF(arrivalFlights-1), digits = 5)
arrivalIndex <- arrivalFlights
IATA <- names(arrivalFlights)
arrivalIndexTable <- as.data.frame(cbind(IATA,arrivalFlights,arrivalIndex))
rownames(arrivalIndexTable) <- NULL
arrivalIndexTable

# 1.9 - Calculer un indice d'achalandage des aéroports en fonction de la quantité de routes en provenance
departureFlights <- table(routesCanada$sourceAirport)
max(departureFlights)
mu <- mean(departureFlights)
var(departureFlights)
sigma <- sd(departureFlights)
head(sort(departureFlights,decreasing = TRUE),n = 30)
departureCDF <- ecdf(departureFlights)
departureIndex <- format(departureCDF(departureFlights-1), digits = 5)
departureIndex <- departureFlights
IATA <- names(departureFlights)
departureIndexTable <- as.data.frame(cbind(IATA,departureFlights,departureIndex))
rownames(departureIndexTable) <- NULL
departureIndexTable

# Tracer les index 
par(mfrow=c(1,2))
curve(arrivalCDF(x-1), from = 0,to = 60, n = 100)
curve(departureCDF(x-1), from = 0,to = 60, n = 100)

# 1.10 - Calculer un indice combiné des deux derniers indices
combinedIndex <- (as.numeric(arrivalIndex)+as.numeric(departureIndex))/(2*as.numeric(max(cbind(arrivalIndex,departureIndex))))
combinedIndexTable <- data.frame(arrivalIndexTable$IATA,
                                 arrivalIndexTable$arrivalIndex,
                                 departureIndexTable$departureIndex,
                                 combinedIndex,stringsAsFactors = TRUE)
rownames(combinedIndexTable) <- NULL
colnames(combinedIndexTable) <- c("IATA","arrivalIndex","departureIndex","combinedIndex")
combinedIndexTable
airportsCanada <- sqldf("
  select 
    a.*,
    coalesce(b.combinedIndex,0) as combinedIndex
  from airportsCanada a
  left join combinedIndexTable b
  on a.IATA = b.IATA")
airportsCanada <- data.frame(as.matrix(airportsCanada ),stringsAsFactors = TRUE)

#1.11 - Créer des cartes permettant de visualiser ces indices grâce à un graphique à bulles
par(mfrow=c(1,1))
lon <- as.numeric(paste(airportsCanada$longitude))
lat <- as.numeric(paste(airportsCanada$latitude))
size <- as.numeric(paste(airportsCanada$combinedIndex))
airportsCoord <- as.data.frame(cbind(lon, lat, size))
mapPoints <- 
  ggmap(map) + 
  geom_point(data=airportsCoord,aes(x=lon,y=lat,size=size),alpha=0.5,shape=16)
mapTraffic <-  
  mapPoints + 
  scale_size_continuous(range = c(0, 20),name = "Traffic Index")
mapTraffic

#### Question 2 #####

# Fonction de calcul de distance entre deux aéroports
library(geosphere)
# PRE nécessite l'existence de la base de donnée 
airportsDist <- function(sourceIATA,destIATA)
{
  # vérifions que sourceIATA et destIATA sont des IATA valides
  sourceFindIndex <- match(sourceIATA,airportsCanada$IATA)
  if(is.na(sourceFindIndex))
  {
    stop(paste('sourceIATA :',sourceIATA,'is not a valid IATA code'))
  }
  destFindIndex <- match(destIATA,airportsCanada$IATA)
  if(is.na(destFindIndex))
  {
    stop(paste('destIATA :',destIATA,'is not a valid IATA code'))
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
airportsDist('AAA','YQB')
airportsDist('YUL','AAA')
airportsDist('YPA','YQB')
airportsDist('YUL','YQB')
airportsDist('YUL','YQB')$value

# Fonction pour déterminer l'heure d'arriver
# install.packages("lubridate")
library(lubridate)
arrivalTime <- function(sourceIATA,destIATA)
{
  topSpeed <- 850
  adjustFactor <- list()
  adjustFactor$a <- 0.0001007194
  adjustFactor$b <- 0.4273381
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

#Importer les taux de taxation par province directement du web
#install.packages("XML")
#install.packages("RCurl")
#install.packages("rlist")
library(XML)
library(RCurl)
library(rlist)
theurl <- getURL("http://www.calculconversion.com/sales-tax-calculator-hst-gst.html",.opts = list(ssl.verifypeer = FALSE) )
tables <- readHTMLTable(theurl)
provinceName <- as.character(sort(unique(airportsCanada$province)))
taxRates <- as.data.frame(cbind(provinceName,as.numeric(sub("%","",tables$`NULL`[-13,5]))/100+1),stringsAsFactors = TRUE)
colnames(taxRates) <- c("province","taxRate")
taxRates

# Fonction de calcul des coûts
shippingCost <- function(sourceIATA, destIATA, weight, 
                         percentCredit = 0, dollarCredit = 0)
{
  # sourceIATA as a string
  # destIATA as a string
  # weight as an integer ; in KG
  # percentCredit as a default float
  # dollarCredit as a default float

  # vérifions qu'il existe une route entre sourceIATA et destIATA 
  routeConcat <- as.character(paste(routesCanada$sourceAirport,routesCanada$destinationAirport))
  if(is.na(match(paste(sourceIATA,destIATA),routeConcat)))
  {
    stop(paste('the combination of sourceIATA and destIATA (',sourceIATA,'-',destIATA,') do not corresponds to existing route'))
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
  distanceFactor <- 0.025
  weightFactor <- 0.5
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
  automatedCredit <-  automatedCredit * ifelse(weight < 1, 0.9, 1)
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
  if(distance$value > 2000)
  {
    automatedCredit <- automatedCredit * 0.9
  }
  else if(distance$value >= 2500)
  {
    automatedCredit <- automatedCredit * 0.85
  }
  else if(distance$value >= 3000)
  {
    automatedCredit <- automatedCredit * 0.825
  }
  else if(distance$value >= 3500)
  {
    automatedCredit <- automatedCredit * 0.8125
  }
  
  # Calculation of taxe rate and control of text
  taxRate <- as.numeric(paste(taxRates[match(airportsCanada[distance$sourceIndex,"province"],taxRates$province),"taxRate"]))
  price <- pmax(fixedCost*profitMargin*automatedCredit*taxRate,(baseCost*automatedCredit*profitMargin - dollarCredit)*(1 - percentCredit)*taxRate)

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

#### Question 3 ####
curve(shippingCost("YUL","YQB",x)$price,0.01,50,ylim=c(0,200),
      main="Shipping Variation with Weight",xlab="weight (Kg)",
      ylab="price (CND $)",lwd = 2)
curve(shippingCost("YUL","YVR",x)$price,0.01,50,xlab="weight (Kg)",
      ylab="price (CND $)",add=TRUE, col = "red", lwd = 2)
curve(shippingCost("YUL","YYZ",x)$price,0.01,50,xlab="weight (Kg)",
      ylab="price (CND $)",add=TRUE, col = "blue", lwd = 2)
curve(shippingCost("YUL","YYC",x)$price,0.01,50,xlab="weight (Kg)",
      ylab="price (CND $)",add=TRUE, col = "purple", lwd = 2)
text(x=c(45,45,45,45),y=c(50,110,140,175),c("YUL-YYZ","YUL-YQB","YUL-YVR","YUL-YYC"),adj = 0.5,cex = 0.75,font = 2,col = c("blue","black","red","purple"))

#### Question 4 ####
# Import data
compData <- read.csv(paste(path,"/Reference/benchmark.csv",sep=''))
colnames(compData) <- c("weight","distance","price")
View(compData) 
summary(compData)

# Weight visualisation
hist(compData$Poids, freq = TRUE, main = "Répartition data..", xlab = "Poids (Kg)", col = "cadetblue")
plot(sort(compData$Poids), (1:length(compData$Poids)) / 100000, xlab = "Poids (Kg)", ylim = c(0,1), ylab = ".." )

# Distance visualisation
hist(compData$Distance, freq = TRUE, main = "Répartition data..", xlab = "Distance (Km)", col = "cadetblue")
plot(sort(compData$Distance), (1:length(compData$Distance)) / 100000, xlab = "Distance (Km)", ylim = c(0,1), ylab = ".." )

# Linear model without intercept
modelsComp<- lm(Prix~ Poids + Distance, compData)
modelsComp

# We plot the model
plot(modelsComp)

# We take a look at the ANOVA table
aov(modelsComp)


#### Question 5 ####
# install.packages("actuar")
library("actuar")
optim()
min.RSS <- function(par) 
{
  sum(par[1] + par[2] * compData$poids  + par[3]- log(compData$prix))
}
modelsComp$coefficients
compData$Poids
optim(c(12.87026884, 0.89780508, 0.03514046), min.RSS)

#### Question 6 ####
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