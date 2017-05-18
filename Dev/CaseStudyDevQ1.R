#
# This is the main code for the Case Study R à Québec 2017
#
# Author : David Beauchemin & Samuel Cabral Cruz
#

#### Setting working directory properly ####
getwd()
setwd('..')
(path <- getwd())
set.seed(31459)

#### Question 1 - Data extraction, processing, visualization and analysis ####

# 1.1 - Database extraction of airports.dat, routes.dat and airlines.dat.
airports <- read.csv("https://raw.githubusercontent.com/jpatokal/openflights/master/data/airports.dat", header = FALSE, na.strings=c('\\N',''))
routes <- read.csv("https://raw.githubusercontent.com/jpatokal/openflights/master/data/routes.dat", header = FALSE, na.strings=c('\\N',''))
airlines <- read.csv("https://raw.githubusercontent.com/jpatokal/openflights/master/data/airlines.dat", header = FALSE, na.strings=c('\\N',''))

# 1.2 - Coloumns names assignation  base on the information available on the website.
colnames(airports) <- c("airportID", "name", "city", "country", "IATA", "ICAO",
                        "latitude", "longitude", "altitude", "timezone", "DST",
                        "tzFormat","typeAirport","Source")
colnames(routes) <- c("airline","airlineID","sourceAirport","sourceAirportID",
                      "destinationAirport","destinationAirportID","codeshare",
                      "stops","equipment")
colnames(airlines) <- c("airlineID","name","alias","IATA","ICAO","Callsign","Country","Active")

# 1.3 - Keeping the Canada information of the dataset
airportsCanada <- airports[airports$country=='Canada',]

# 1.4 - Extraction of the genreral information about the distributions of the variables in the dataset and 
# understanding of the signification of those variables and the different modalities they can take.

# Those are the principal R function to easely visualize information.
View(airportsCanada)
head(airportsCanada)
summary(airportsCanada)

nbAirportCity <- table(airportsCanada$city)  
(nbAirportCity <- sort(nbAirportCity,decreasing=TRUE))[1:10]

# The relevance of the data.
# 1.5 - Correct the modalities of the variables and make a selection of those wo seem useful for the rest of the treatment. 
# We observe that the variables typeAirport and Source are useless in our situation since we only use information on air transport. 
# A similar reasoning is applicable for the country variable which will only have the modality Canada.
airportsCanada <- subset(airportsCanada, select = -c(country, typeAirport, Source ))


# As seen in the sumary, we dont have the IATA for 27 airports
airportsCanada[is.na(airportsCanada$IATA),c("airportID","name","IATA","ICAO")]

# The first option, is to simply ignore these airports in the rest of the analysis.
# However, all these airports have a well-defined ICAO code which will allow a default value to be assigned.
# Since 82% of the IACA is the last three caracters of the ICAO, we will simply use the derivate IATA from the ICAO.
sum(airportsCanada$IATA==substr(airportsCanada$ICAO,2,4),na.rm = TRUE)/sum(!is.na(airportsCanada$IATA))

# We are now able to fill the missing IATA and we delete the ICAO since it's now useless
airportsCanada$IATA <- as.character(airportsCanada$IATA) 
# We fill the NA with the substring ICAO
airportsCanada$IATA[is.na(airportsCanada$IATA)] <- substr(airportsCanada$ICAO[is.na(airportsCanada$IATA)],2,4) 
airportsCanada$IATA <- as.factor(airportsCanada$IATA)
airportsCanada <- subset(airportsCanada, select = - ICAO)
View(airportsCanada)

# Finaly, we are missing more than fifty time zone
missingTZ <- airportsCanada[is.na(airportsCanada$timezone),]

# Since the TZ depend only on the geographical position, two options are available to us : 
# 1) Deduce the information from other close airport;
# 2) Locate the real time zone by mapping tools.
# We will use the second option which may seem more complex but with the proper tools become more easy and accurate.

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

# We can also note that we only have information derived from the province in which each airport is located with the city.
# Since we want to apply taxes by province in our situation, we will need a better data to access this informaiton. 
# We will again use mapping techniques to extract the province as a function of the x and y coordinates.
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

# Since the timezone, DST and city are now useless, we remove them from the dataset.
# Plus, we withdraw tzFormat because it's incomplet and we will use the tzmerge data to replace will a complete data. 
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

# This code will give the same result :
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
# As we can see, there are only two flights that are not direct.
# For the sake of simplicity, we will consider all flights as direct flights.
# Moreover, the notion of codeshare will not be useful since the delivery of 
# merchandise can be done as much through an air agency as by private flight.
# Then we get rid of these variables.
routesCanada <- subset(routesCanada, select = -c(codeshare, stops))
summary(routesCanada)

# 1.6 - Create a map showing the different airports on a map of Canada.
# install.packages("ggmap")
library(ggmap)
map <- get_map(location = 'Canada', zoom = 3)
lon <- as.numeric(paste(airportsCanada$longitude))
lat <- as.numeric(paste(airportsCanada$latitude))
airportsCoord <- as.data.frame(cbind(lon, lat))
(mapPoints <- ggmap(map) + geom_point(data=airportsCoord,aes(lon,lat),alpha=0.5))

# 1.7 - Create a second map showing all possible routes between these different airports.
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

# Calculate an airport ridership index based on the number of incoming routes.
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

# Index drawing
curve(totalFlightsCDF(x-1),from = 0,to = 60,n = 100,
      xlab = "Nombre de routes par aéroport", 
      ylab = "CDF")

# Calculate a combined index from the index
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

#1.11 - Create maps to visualize these indices using a bubble graph
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
