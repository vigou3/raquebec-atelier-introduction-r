# Code source Case Study R à Québec 2017

#### Setting working directory properly ####
getwd()
#setwd('C:/Users/Samuel/Documents/ColloqueR/Dev')
setwd('..')
(path <- getwd())
set.seed(31459)

#### Question 1 - Data extraction, processing, visualization and analysis ####

# 1.1 - Database extraction of airports.dat, routes.dat and airlines.dat
airports <- read.csv("https://raw.githubusercontent.com/jpatokal/openflights/master/data/airports.dat", header = FALSE, na.strings=c('\\N',''))
routes <- read.csv("https://raw.githubusercontent.com/jpatokal/openflights/master/data/routes.dat", header = FALSE, na.strings=c('\\N',''))
airlines <- read.csv("https://raw.githubusercontent.com/jpatokal/openflights/master/data/airlines.dat", header = FALSE, na.strings=c('\\N',''))

# 1.2 - Coloumns names assignation  base on the information available on the website
colnames(airports) <- c("airportID", "name", "city", "country", "IATA", "ICAO",
                        "latitude", "longitude", "altitude", "timezone", "DST",
                        "tzFormat","typeAirport","Source")
colnames(routes) <- c("airline","airlineID","sourceAirport","sourceAirportID",
                      "destinationAirport","destinationAirportID","codeshare",
                      "stops","equipment")
colnames(airlines) <- c("airlineID","name","alias","IATA","ICAO","Callsign","Country","Active")

# 1.3 - Keeping the Canada information of the dataset
airportsCanada <- airports[airports$country=='Canada',]
airportsCanada2 <- subset(airports,country == 'Canada')
all.equal(airportsCanada,airportsCanada2)

# 1.4 - Extraire des informations générales sur la distribution des variables présentent dans le jeu de données 
# et vous informer sur la signification de ces dernières ainsi que sur les différentes modalités quelles peuvent 
# prendre

#Voici différente fonction R qui vous permette de visualiser les données
View(airportsCanada)
head(airportsCanada)
summary(airportsCanada)

nbAirportCity <- table(as.character(airportsCanada$city))   #We use as.character to convert the factor into a fixed caractor
(nbAirportCity <- sort(nbAirportCity,decreasing=TRUE))[1:10]

# Filtrer la pertinence des données
# 1.5 - Corriger les modalités des variables et faire une sélection des variables qui vous semble utiles 
# pour le reste du traitement
# Nous observons que les variables typeAirport et Source ne sont d'aucune utilité dans la situation présente
# compte tenu que nous n'utilisons que l'information sur le transport par voies aériennes.
# Un raisonnement similaire est applicable pour la variable country qui ne possèdera que la modalité Canada
airportsCanada <- subset(airportsCanada, select = -c(country, typeAirport, Source ))


# As seen in the sumary, we dont have the IATA for 27 airports
airportsCanada[is.na(airportsCanada$IATA),c("airportID","name","IATA","ICAO")]
subset(airportsCanada, is.na(IATA), select = c("airportID","name","IATA","ICAO"))

# Cependant, toutes ces aéroports possèdent un code ICAO bien défini ce qui permettra d'attribuer une valeur
# par défaut. Une autre possibilité aurait été de simplement ignorer ces aéroports dans le reste de l'analyse.
# Cette approximation ne semble pas trop contraignante compte tenu du fait que les trois derniers caractères
# du code ICAO correspondent au code IATA dans 82% des cas.
sum(airportsCanada$IATA==substr(airportsCanada$ICAO,2,4),na.rm = TRUE)/sum(!is.na(airportsCanada$IATA))

# We are now able to fill the missing IATA and we delete the IACO since it's now useless
airportsCanada$IATA <- as.character(airportsCanada$IATA) 
# We fill the NA with the substring ICAO
airportsCanada$IATA[is.na(airportsCanada$IATA)] <- substr(airportsCanada$ICAO[is.na(airportsCanada$IATA)],2,4) 
airportsCanada$IATA <- as.factor(airportsCanada$IATA)
airportsCanada <- subset(airportsCanada, select = - ICAO)
View(airportsCanada)

# Finaly, we are missing more than fifty time zone
missingTZ <- airportsCanada[is.na(airportsCanada$timezone),]

# Since the TZ depend only on the geographical position, two options are available to us : 
# 1) Deduce the information from other close airport
# 2) Locate the real time zone by mapping tools
# We will use the second option which may seem more complex but with the proper tools become more easy and accurate

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
airportsCanada <- data.frame(as.matrix(airportsCanada))

# On retire timezone et DST car les données sont inutiles
# On retire tzFormat car il s'Agit des données incomplet et on le remplace plus tard par tzMerged
# On retire city qui ne sera plus utile puisque nous avons maintenant la province
airportsCanada <- subset(airportsCanada, select = -c(timezone, DST, tzFormat, city ))
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
routesCanada  <- data.frame(as.matrix(routesCanada ))

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
(airlinesCanada <- sqldf("
  select *
  from airlines
  where IATA in (select distinct airline
                 from routesCanada)"))
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

# 1.6 - Créer une carte affichant les différents aéroports sur une carte du Canada
# install.packages("ggmap")
library(ggmap)
map <- get_map(location = 'Canada', zoom = 3)
lon <- as.numeric(paste(airportsCanada$longitude))
lat <- as.numeric(paste(airportsCanada$latitude))
airportsCoord <- as.data.frame(cbind(lon, lat))
(mapPoints <- ggmap(map) + geom_point(data=airportsCoord,aes(lon,lat),alpha=0.5))

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
(mapRoutes <- mapPoints + geom_segment(data=routesCoord,aes(x=lonBeg,y=latBeg,xend=lonEnd,yend=latEnd),alpha=0.5))

# Calculer un indice d'achalandage des aéroports en fonction de la quantitée de routes en destination
arrivalFlights <- table(routesCanada$destinationAirport)
departureFlights <- table(routesCanada$sourceAirport)
totalFlights <- arrivalFlights + departureFlights
max(totalFlights)
mean(totalFlights)
var(totalFlights)
sd(totalFlights)
head(sort(totalFlights,decreasing = TRUE),n = 30)
totalFlightsCDF <- ecdf(totalFlights)
IATA <- names(totalFlights)

# Tracer l'index
curve(totalFlightsCDF(x-1),from = 0,to = 60,n = 100,
      xlab = "Nombre de routes par aéroport", 
      ylab = "CDF")

# Calculer un indice combiné des deux derniers indices 
combinedIndex <- round(totalFlights/max(totalFlights),3)
combinedIndexTable <- data.frame(IATA,
                                 as.numeric(paste(totalFlights)),
                                 as.numeric(paste(combinedIndex)))
rownames(combinedIndexTable) <- NULL
colnames(combinedIndexTable) <- c("IATA","totalFlights","combinedIndex")
combinedIndexTable
airportsCanada <- sqldf("
  select 
    a.*,
    coalesce(b.combinedIndex,0) as combinedIndex
  from airportsCanada a
  left join combinedIndexTable b
  on a.IATA = b.IATA")
airportsCanada <- data.frame(as.matrix(airportsCanada ))

#1.11 - Créer des cartes permettant de visualiser ces indices grâce à un graphique à bulles
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
