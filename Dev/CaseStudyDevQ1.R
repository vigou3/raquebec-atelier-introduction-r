### RStudio: -*- coding: utf-8 -*-
##
## Copyright (C) 2017 David Beauchemin, Samuel Cabral Cruz, Vincent Goulet
##
## This file is part of the project 
## «Introduction à R - Atelier du colloque R à Québec 2017»
## http://github.com/vigou3/raquebec-atelier-introduction-r
##
## The creation is made available according to the license
## Attribution-Sharing in the same conditions 4.0
## of Creative Commons International
## http://creativecommons.org/licenses/by-sa/4.0/

#### Setting working directory properly ####
setwd("C:/Users/Samuel/Documents/ColloqueR/Dev")
getwd()
setwd("..")
(path <- getwd())
set.seed(31459)

#### Data extraction, cleaning, visualization and analysis #### 

# Extraction of airports.dat and routes.dat
airports <- read.csv("https://raw.githubusercontent.com/jpatokal/openflights/master/data/airports.dat",
                     header = FALSE, na.strings=c("\\N",""))
routes <- read.csv("https://raw.githubusercontent.com/jpatokal/openflights/master/data/routes.dat", 
                   header = FALSE, na.strings=c("\\N",""))

# Coloumns names assignation based on the information available on the website
# https://openflights.org/data.html
colnames(airports) <- c("airportID", "name", "city", "country", "IATA", "ICAO",
                        "latitude", "longitude", "altitude", "timezone", "DST",
                        "tzFormat","typeAirport","Source")
colnames(routes) <- c("airline","airlineID","sourceAirport","sourceAirportID",
                      "destinationAirport","destinationAirportID","codeshare",
                      "stops","equipment")

# Filtering the observations relative to Canadian airports
airportsCanada <- subset(airports,country == "Canada")

# Extraction of genreral information about the variables contained in the dataset
View(airportsCanada)
summary(airportsCanada)
nbAirportCity <- table(airportsCanada$city)
(nbAirportCity <- head(sort(nbAirportCity,decreasing=TRUE)))

# Variable selection 
# We will not use the typeAirport and Source variables since we only want to analyse air transport market
# We can also discard the country variable because we already filtered on Canadian airports
airportsCanada <- subset(airportsCanada, select = -c(country, typeAirport, Source ))

# As seen in the summary, we do not have the IATA code of 27 airports
subset(airportsCanada, is.na(IATA), select = c("airportID","name","IATA","ICAO"))

# 82% of the time, the IATA code corresponds to the last three characters of the ICAO code
# We will use this relationship to assign default value for missing IATA codes
IATA <- as.character(airportsCanada$IATA)
ICAO <- as.character(airportsCanada$ICAO)
i <- is.na(IATA)
sum(IATA == substr(ICAO,2,4),na.rm = TRUE)/sum(!i)
IATA[i] <- substr(ICAO[i],2,4)
airportsCanada$IATA <- as.factor(IATA)
summary(airportsCanada)
# We will not need the ICAO code anymore
airportsCanada <- subset(airportsCanada, select = - ICAO)

# Finaly, we are missing more than fifty time zone.
missingTZ <- airportsCanada[is.na(airportsCanada$timezone),]

# Since the TZ depend only on the geographical position, two options are available to us : 
# 1) Deduce the information from other close airport;
# 2) Locate the real time zone by mapping tools.
# We will use the second option which may seem more complex but with the proper tools become more easy and accurate.

# install.packages("sp")
# install.packages("rgdal")
library(sp)
library(rgdal)
tz_world.shape <- readOGR(dsn=paste(path,"/Reference/tz_world",sep=""),layer="tz_world")
unknown_tz <- airportsCanada[is.na(airportsCanada$tzFormat),c("airportID","name","longitude","latitude")]
sppts <- SpatialPoints(unknown_tz[,c("longitude","latitude")])
proj4string(sppts) <- CRS("+proj=longlat")
sppts <- spTransform(sppts, proj4string(tz_world.shape))
merged_tz <- cbind(unknown_tz,over(sppts,tz_world.shape))

# We can also note that we only have information derived from the province in which each airport is located with the city.
# Since we want to apply taxes by province in our situation, we will need a better data to access this informaiton. 
# We will again use mapping techniques to extract the province as a function of the x and y coordinates.
prov_terr.shape <- readOGR(dsn=paste(path,"/Reference/prov_terr",sep=""),layer="gpr_000b11a_e")
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
routesCanada[is.na(routesCanada$airlineID),]
unique(routesCanada$airlineID)
unique(routesCanada[is.na(routesCanada$airlineID),]$airline)
summary(routesCanada$stops)

# As we can see, there are only two flights that are not direct.
# For the sake of simplicity, we will consider all flights as direct flights.
# Moreover, the notion of codeshare will not be useful since the delivery of 
# merchandise can be done as much through an air agency as by private flight.
# In conclusion, we get rid of these variables.
routesCanada <- subset(routesCanada, select = -c(codeshare, stops))
summary(routesCanada)

# 1.6 - Create a map showing the different airports on a map of Canada. install.packages("ggmap")
library(ggmap)
map <- get_map(location = "Canada", zoom = 3)
lon <- as.numeric(paste(airportsCanada$longitude))
lat <- as.numeric(paste(airportsCanada$latitude))
airportsCoord <- as.data.frame(lon, lat)
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
      xlab = "Nombre de routes par aeroport", 
      ylab = "CDF")

# Calculate a combined index from the index.
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

# 1.11 - Create maps to visualize these indices using a bubble graph.
TraficData <- subset(airportsCanada,as.numeric(paste(combinedIndex)) > 0.05)
lon <- as.numeric(paste(TraficData$longitude))
lat <- as.numeric(paste(TraficData$latitude))
size <- as.numeric(paste(TraficData$combinedIndex))
airportsCoord <- as.data.frame(cbind(lon, lat, size))
mapPoints <- 
  ggmap(map) + 
  geom_point(data=TraficData,aes(x=lon,y=lat,size=size),alpha=0.5,shape=16)
(mapTraffic <-  
  mapPoints + 
  scale_size_continuous(range = c(0, 20),name = "Trafic Index"))

# install.package("leaflet")
library(leaflet)
url <- "http://hiking.waymarkedtrails.org/en/routebrowser/1225378/gpx"
download.file(url, destfile = paste(path,"/Reference/worldRoutes.gpx",sep=""), method = "wget")
worldRoutes <- readOGR(paste(path,"/Reference/worldRoutes.gpx",sep=""), layer = "tracks")
markersData <- subset(airportsCanada,IATA %in% c("YUL","YVR","YYZ","YQB"))
markersWeb <- c("https://www.aeroportdequebec.com/fr/pages/accueil",
                "http://www.admtl.com/",
                "http://www.yvr.ca/en/passengers",
                "https://www.torontopearson.com/")

# Defining the description text to be displayed by the markers
descriptions <-paste("<b><FONT COLOR=#31B404> Airport Details</FONT></b> <br>",
                    "<b>IATA: <a href=",markersWeb,">",markersData$IATA,"</a></b><br>",
                    "<b>Name:</b>",markersData$name,"<br>",
                    "<b>Coord.</b>: (",markersData$longitude,",",markersData$latitude,") <br>",
                    "<b>Trafic Index:</b>",markersData$combinedIndex)

# Defining the icon to be add on the markers from fontawesome library
icons <- awesomeIcons(icon = "paper-plane",
                      iconColor = "black",
                      library = "fa")

# Combinaison of the different components in order to create a standalone map
(mapTraffic <- leaflet(worldRoutes) %>%
    addTiles(urlTemplate = "http://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png") %>%
    addCircleMarkers(stroke = FALSE,data = TraficData, 
                     ~as.numeric(paste(longitude)), ~as.numeric(paste(latitude)),
                     color = "black", fillColor = "green",
                     radius = ~as.numeric(paste(combinedIndex))*30, opacity = 0.5) %>%
    addAwesomeMarkers(data = markersData, ~as.numeric(paste(longitude)), 
                      ~as.numeric(paste(latitude)), popup = descriptions,icon=icons))

# Resizing of the map
mapTraffic$width <- 874
mapTraffic$height <- 700

# Export of the map into html format
# install.packages("htmlwidgets")
library(htmlwidgets)
saveWidget(mapTraffic, paste(path,"/Reference/leafletTrafic.html",sep = ""), selfcontained = TRUE)

# addMarkers(data = subset(airportsCanada,IATA %in% c("YUL","YVR","YYZ","YQB")), 
# ~as.numeric(paste(longitude)), ~as.numeric(paste(latitude)), popup = ~IATA) %>%

