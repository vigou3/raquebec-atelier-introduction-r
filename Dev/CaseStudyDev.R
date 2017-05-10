#Setting working directory properly
setwd('..')
(path <- getwd())
#Question 1 - Extraction, traitement, visualisation et analyse des données
#1.1 - Extraire les bases de données airports.dat et routes.dat
airports <- read.csv("https://raw.githubusercontent.com/jpatokal/openflights/master/data/airports.dat", header = FALSE, na.strings=c('\\N',''))
routes <- read.csv("https://raw.githubusercontent.com/jpatokal/openflights/master/data/routes.dat", header = FALSE, na.strings=c('\\N',''))

#1.2 - Attribuer des noms aux colonnes du jeu de données en vous fiant à l'information disponible sur le site
colnames(airports) <- c("airportID", "name", "city", "country", "IATA", "ICAO",
                        "latitude", "longitude", "altitude", "timezone", "DST",
                        "tzFormat","typeAirport","Source")
colnames(routes) <- c("airline","airlineID","sourceAirport","sourceAirportID",
                      "destinationAirport","destinationAirportID","codeshare",
                      "stops","equipment")

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
library(foreign)
tz_world.data <- read.dbf(paste(path,"/Reference/tz_world/tz_world.dbf",sep=''), as.is = FALSE)
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

install.packages("ggmap")
library(ggmap)
map <- get_map(location = 'Canada',zoom=4)
mapPoints <- ggmap(map) +
  +   geom_point(aes(x = lon, y = lat, size = sqrt(flights)), data = airportD, alpha = .5)
plot(map)

x <- Sys.time()
y <- Sys.timezone()
class(x)

install.packages("lubridate")
library(lubridate)
x
with_tz(x, tzone = "America/Vancouver")

unique(airports[!is.na(airports$tzFormat),c("timezone","DST","tzFormat")])
summary(airports)





routes <- routes[!is.na(match(routes$sourceAirportID,airports$airportID)) &
                   !is.na(match(routes$destinationAirportID,airports$airportID)),]
#Produira le même résultat
#routes <- routes[!is.na(match(routes$sourceAirport,airports$IATA)) &
#                 !is.na(match(routes$destinationAirport,airports$IATA)),]


summary(routes)
head(routes)
