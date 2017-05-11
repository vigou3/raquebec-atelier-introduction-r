#
# Code source Case Study R à Québec 2017
#


# Setting working directory properly
setwd('..')
(path <- getwd())
set.seed(31459)


#### Question 1 - Extraction, traitement, visualisation et analyse des données ####


# 1.1 - Extraire les bases de données airports.dat et routes.dat
airports <- read.csv("https://raw.githubusercontent.com/jpatokal/openflights/master/data/airports.dat", header = FALSE, na.strings=c('\\N',''))
routes <- read.csv("https://raw.githubusercontent.com/jpatokal/openflights/master/data/routes.dat", header = FALSE, na.strings=c('\\N',''))
airlines <- read.csv("https://raw.githubusercontent.com/jpatokal/openflights/master/data/airlines.dat", header = FALSE, na.strings=c('\\N',''))

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

# install.packages("sqldf")
library(sqldf)
airportsCanada <- sqldf("
  select a.*, coalesce(a.tzFormat,b.TZID) as tzMerged
  from airportsCanada a 
  left join merged_tz b
  on a.airportID = b.airportID
  order by a.airportID")
airportsCanada <- data.frame(as.matrix(airportsCanada),stringsAsFactors = TRUE)

# On retire timezone et DST car les données sont inutiles
# On retire tzFormat car il s'Agit des données incomplet et on le remplace plus tard par tzMerged
airportsCanada <- airportsCanada[,-match(c("timezone","DST","tzFormat"),colnames(airportsCanada))]
summary(airportsCanada)

# install.packages("plyr")
library(plyr)
airportsCanada <- rename(airportsCanada, c("tzMerged"="tzFormat"))
summary(airportsCanada)


routesCanada <- sqldf("
  select *
  from routes
  where sourceAirportID in (select distinct airportID
                            from airportsCanada)
    and destinationAirportID in (select distinct airportID
                                 from airportsCanada)")
routesCanada  <- data.frame(as.matrix(routesCanada ),stringsAsFactors = TRUE)

#
# Produira le même résultat
# x <- routesCanada[!is.na(match(routesCanada$sourceAirportID,airportsCanada$airportID)) &
#              !is.na(match(routesCanada$destinationAirportID,airportsCanada$airportID)),]
# routesCanada <- routesCanada[!is.na(match(routesCanada$sourceAirport,airportsCanada$IATA)) &
#                 !is.na(match(routesCanada$destinationAirport,airportsCanada$IATA)),]
#

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
map <- get_map(location = 'Canada',zoom=3)
lon <- as.numeric(paste(airportsCanada$longitude))
lat <- as.numeric(paste(airportsCanada$latitude))
airportsCoord <- as.data.frame(lon, lat)
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
    on a.destinationAirport = c.IATA"
)
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
arrivalIndex <- format(arrivalFlights, digits = 5)
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
departureIndex <- format(departureFlights, digits = 5)
IATA <- names(departureFlights)
departureIndexTable <- as.data.frame(cbind(IATA,departureFlights,departureIndex))
rownames(departureIndexTable) <- NULL
departureIndexTable

# Tracer les index 
par(mfrow=c(1,2))
curve(arrivalCDF(x-1), from = 0,to = 60, n = 100)
curve(departureCDF(x-1), from = 0,to = 60, n = 100)

# 1.10 - Calculer un indice combiné des deux derniers indices
combinedIndex <- (as.numeric(arrivalIndex)+as.numeric(departureIndex))/2
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

library(geosphere)

# distance
#PRE nécessite l'existence de la base de donnée 
dist <- function(sourceIATA,destIATA)
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
  # vérifions qu'il existe une route entre sourceIATA et destIATA 
  #(n'est pas nécessaire puisque nous pourrions être intéressé à connaître la distance
  #entre deux aéroports n'ayant toujours pas de route entre eux)
  routeConcat <- as.character(paste(routesCanada$sourceAirport,routesCanada$destinationAirport))
  if(is.na(match(paste(sourceIATA,destIATA),routeConcat)))
  {
    stop(paste('the combination of sourceIATA and destIATA (',sourceIATA,'-',destIATA,'do not corresponds to existing route'))
  }
  sourceLon <- as.numeric(paste(airportsCanada$longitude))[sourceFindIndex]
  sourceLat <- as.numeric(paste(airportsCanada$latitude))[sourceFindIndex]
  sourceCoord <- c(sourceLon,sourceLat)
  destLon <- as.numeric(paste(airportsCanada$longitude))[destFindIndex]
  destLat <- as.numeric(paste(airportsCanada$latitude))[destFindIndex]
  destCoord <- c(destLon,destLat)
  distList <- list()
  distList$source <- sourceIATA
  distList$dest <- destIATA
  distList$value <- round(distGeo(sourceCoord,destCoord)/1000)
  distList$metric <- "Km"
  distList$xy_dist <- sqrt((sourceLon - destLon)**2 + (sourceLat - destLat)**2)
  distList
}
dist('AAA','YQB')
dist('YUL','AAA')
dist('YPA','YQB')
dist('YUL','YQB')
dist('YUL','YQB')$value

# time conversion
x <- Sys.time()
y <- Sys.timezone()
class(x)
# install.packages("lubridate")
library(lubridate)
x
with_tz(x, tzone = "America/Vancouver")


#### Question 3 ####


#### Question 4 ####

# Génération du fichier benchmark.csv
n <- 100000
x <- matrix(runif(4*n),ncol = 4,byrow = TRUE)

# Générer des poids selon logNormale
mu1 <- log(3000)
sigma1 <- log(1.8)
exp(mu1+sigma1**2/2)
exp(2*mu1+4*sigma1**2/2)-exp(mu1+sigma1**2/2)**2
weights <- qlnorm(x[,1],mu1,sigma1)
mean(weights)
weights
hist(weights,breaks = 100)
max(weights)*2.2/1000

# Générer des distances selon logNormale
routesCanada
routesIATA <- cbind(paste(routesCanada$sourceAirport),paste(routesCanada$destinationAirport))
routesDistance <- apply(routesIATA, 1, function(x) dist(x[1],x[2])$value)
max(routesDistance)
mean(routesDistance)
mu2 <- log(650)
sigma2 <- log(1.4)
distances <- qlnorm(x[,2],mu2,sigma2)
mean(distances)
distances
hist(distances,breaks = 100)
max(distances)

# Générer des erreurs sur le poids
weightsTarifParamA <- 5/1000
weightsTarifParamB <- 5
weightsPrice <- weightsTarifParamA*weights+weightsTarifParamB
weightsError <- pnorm((x[,3]-0.5)*sqrt(12))*sd(weights)*weightsTarifParamA
weightsPriceFinal <- weightsPrice + weightsError
cbind(weights,weightsPriceFinal)
