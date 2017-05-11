#Setting working directory properly
setwd('..')
(path <- getwd())
#Question 1 - Extraction, traitement, visualisation et analyse des données
#1.1 - Extraire les bases de données airports.dat et routes.dat
airports <- read.csv("https://raw.githubusercontent.com/jpatokal/openflights/master/data/airports.dat", header = FALSE, na.strings=c('\\N',''))
routes <- read.csv("https://raw.githubusercontent.com/jpatokal/openflights/master/data/routes.dat", header = FALSE, na.strings=c('\\N',''))
airlines <- read.csv("https://raw.githubusercontent.com/jpatokal/openflights/master/data/airlines.dat", header = FALSE, na.strings=c('\\N',''))

#1.2 - Attribuer des noms aux colonnes du jeu de données en vous fiant à l'information disponible sur le site
colnames(airports) <- c("airportID", "name", "city", "country", "IATA", "ICAO",
                        "latitude", "longitude", "altitude", "timezone", "DST",
                        "tzFormat","typeAirport","Source")
colnames(routes) <- c("airline","airlineID","sourceAirport","sourceAirportID",
                      "destinationAirport","destinationAirportID","codeshare",
                      "stops","equipment")
colnames(airlines) <- c("airlineID","name","alias","IATA","ICAO","Callsign","Country","Active")

#1.3 - Nettoyer le jeu de données en ne conservant que les données relatives au Canada
airports <- airports[airports$country=='Canada',]

#1.4 - Extraire des informations générales sur la distribution des variables présentent dans le jeu de données 
# et vous informer sur la signification de ces dernières ainsi que sur les différentes modalités quelles peuvent 
# prendre
head(airports)
summary(airports)
nbAirportCity <- table(as.character(airports$city))
(nbAirportCity <- sort(nbAirportCity,decreasing=TRUE))[1:10]

#1.5 - Corriger les modalités des variables et faire une sélection des variables qui vous semble utiles 
# pour le reste du traitement
#Nous observons que les variables typeAirport et Source ne sont d'aucune utilité dans la situation présente
#compte tenu que nous n'utilisons que l'information sur le transport par voies aériennes.
#Un raisonnement similaire est applicable pour la variable country qui ne possèdera que la modalité Canada
airports <- airports[,-match(c("country","typeAirport","Source"),colnames(airports))]
#Nous pouvons aussi constater que 27 aéroports ne possèdent aucun code IATA.
airports[is.na(airports$IATA),c("airportID","name","IATA","ICAO")]
#Cependant, toutes ces aéroports possèdent un code ICAO bien défini ce qui permettra d'attribuer une valeur
#par défaut. Une autre possibilité aurait été de simplement ignorer ces aéroports dans le reste de l'analyse.
#Cette approximation ne semble pas trop contraignante compte tenu du fait que les trois derniers caractères
#du code ICAO correspondent au code IATA dans 82% des cas.
sum(airports$IATA==substr(airports$ICAO,2,4),na.rm = TRUE)/sum(!is.na(airports$IATA))
#Nous modifions donc la variable IATA et nous nous débarasserons de la variable ICAO
airports$IATA <- as.character(airports$IATA)
airports$IATA[is.na(airports$IATA)] <- substr(airports$ICAO[is.na(airports$IATA)],2,4)
airports$IATA <- as.factor(airports$IATA)
airports <- airports[,-match("ICAO",colnames(airports))]
#Finalement, nous voyons qu'il semble y avoir une quarantaine d'aéroport pour lesquels nous n'avons pas
# d'information sur le fuseau horaire
missingTZ <- airports[is.na(airports$timezone),]
#Puisque les fuseaux horaires ne dépendent que de la position géographique, plusieurs options s'offrent à nous:
#1) Trouver des aéroports proches de c'est derniers pour en déduire les informations
#2) Utiliser des outils de cartographie pour retrouver les vrais fuseaux horaires
#Nous utiliserons ici la deuxième option qui peut sembler plus complquée de prime abord, mais qui se révèle
#très simple et beaucoup plus précise lorsque nous avons accès à l'information et aux outils nécessaires
library(rgdal)
tz_world.shape <- readOGR(dsn=paste(path,"/Reference/tz_world",sep=''),layer="tz_world")
library(sp)
unknown_tz <- airports[is.na(airports$tzFormat),c("airportID","name","longitude","latitude")]
sppts <- SpatialPoints(unknown_tz[,c("longitude","latitude")])
proj4string(sppts) <- CRS("+proj=longlat")
sppts <- spTransform(sppts, proj4string(tz_world.shape))
merged_tz <- cbind(unknown_tz,over(sppts,tz_world.shape))

library(sqldf)
airports <- sqldf("
  select a.*, coalesce(a.tzFormat,b.TZID) as tzMerged
  from airports a 
  left join merged_tz b
  on a.airportID = b.airportID
  order by a.airportID")
airports <- data.frame(as.matrix(airports),stringsAsFactors = TRUE)
summary(airports)
airports <- airports[,-match(c("timezone","DST","tzFormat"),colnames(airports))]
library(plyr)
airports <- rename(airports, c("tzMerged"="tzFormat"))
summary(airports)


routes <- sqldf("
  select *
  from routes
  where sourceAirportID in (select distinct airportID
                            from airports)
    and destinationAirportID in (select distinct airportID
                                 from airports)")
routes <- data.frame(as.matrix(routes),stringsAsFactors = TRUE)
#Produira le même résultat
#x <- routes[!is.na(match(routes$sourceAirportID,airports$airportID)) &
#              !is.na(match(routes$destinationAirportID,airports$airportID)),]
#routes <- routes[!is.na(match(routes$sourceAirport,airports$IATA)) &
#                 !is.na(match(routes$destinationAirport,airports$IATA)),]
summary(routes)
unique(routes$airline)
unique(routes[,c("airline","airlineID")])
unique(routes$airlineID)
summary(airlines)
x <- sqldf("
  select *
  from airlines
  where IATA in (select distinct airline
                 from routes)")
x
routes[is.na(routes$airlineID),]
unique(routes$airlineID)
unique(routes[is.na(routes$airlineID),]$airline)
#Comme nous pouvons le remarquer, il n'y a que deux vols qui ne sont pas directs,
#Pour des fins de simplification, nous allons considérer tous les vols comme étant 
#des vols directs
#De plus, la notion de codeshare ne sera pas utile compte tenu que la livraison de
#de marchandise peut autant se faire par l'intermédiaire d'agence aérienne que par 
#vol privé.
#Nous pouvons ainsi nous débarasser de ces variables
routes <- routes[,-match(c("codeshare","stops"),colnames(routes))]
summary(routes)

#1.6 - Créer une carte affichant les différents aéroports sur une carte du Canada
library(ggmap)
map <- get_map(location = 'Canada',zoom=3)
lon <- as.numeric(paste(airports$longitude))
lat <- as.numeric(paste(airports$latitude))
airportsCoord <- as.data.frame(lon,lat)
mapPoints <- ggmap(map) + geom_point(data=airportsCoord,aes(lon,lat),alpha=0.5)
mapPoints

#1.7 - Créer une seconde carte montrant toutes les routes possibles entre ces différents aéroports
summary(routes)
summary(airports)
routesCoord <- sqldf("
  select 
    a.sourceAirport, 
    a.destinationAirport,
    b.longitude as sourceLon,
    b.latitude as sourceLat,
    c.longitude as destLon,
    c.latitude as destLat
  from routes a
  left join airports b
    on a.sourceAirport = b.IATA
  left join airports c
    on a.destinationAirport = c.IATA"
)
lonBeg <- as.numeric(paste(routesCoord$sourceLon))
latBeg <- as.numeric(paste(routesCoord$sourceLat))
lonEnd <- as.numeric(paste(routesCoord$destLon))
latEnd <- as.numeric(paste(routesCoord$destLat))
routesCoord <- as.data.frame(cbind(lonBeg,latBeg,lonEnd,latEnd))
mapRoutes <- mapPoints + geom_segment(data=routesCoord,aes(x=lonBeg,y=latBeg,xend=lonEnd,yend=latEnd),alpha=0.5)
mapRoutes

#1.8 - Calculer un indice d'achalandage des aéroports en fonction de la quantitée de routes en destination
arrivalFlights <- table(routes$destinationAirport)
max(arrivalFlights)
mean(arrivalFlights)
var(arrivalFlights)
sd(arrivalFlights)
head(sort(arrivalFlights,decreasing = TRUE),n = 30)
arrivalCDF <- ecdf(arrivalFlights)
arrivalIndex <- format(arrivalCDF(arrivalFlights-1), digits = 5)
IATA <- names(arrivalFlights)
arrivalIndexTable <- as.data.frame(cbind(IATA,arrivalFlights,arrivalIndex))
rownames(arrivalIndexTable) <- NULL
arrivalIndexTable

#1.9 - Calculer un indice d'achalandage des aéroports en fonction de la quantité de routes en provenance
departureFlights <- table(routes$sourceAirportID)
max(departureFlights)
mean(departureFlights)
var(departureFlights)
sd(departureFlights)
head(sort(departureFlights,decreasing = TRUE),n = 30)
departureCDF <- ecdf(departureFlights)
departureIndex <- format(departureCDF(departureFlights-1), digits = 5)
IATA <- names(departureFlights)
departureIndexTable <- as.data.frame(cbind(IATA,departureFlights,departureIndex))
rownames(departureIndexTable) <- NULL
departureIndexTable


par(mfrow=c(1,2))
curve(arrivalCDF(x-1),from = 0,to = 60, n = 100)
curve(departureCDF(x-1),from = 0,to = 60, n = 100)

#1.10 - Calculer un indice combiné des deux derniers indices
combinedIndex <- pmean(arrivalIndex,departureIndex)

par(mfrow=c(1,1))


#time conversion

x <- Sys.time()
y <- Sys.timezone()
class(x)

install.packages("lubridate")
library(lubridate)
x
with_tz(x, tzone = "America/Vancouver")

unique(airports[!is.na(airports$tzFormat),c("timezone","DST","tzFormat")])
