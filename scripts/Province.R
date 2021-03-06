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


# Setting working directory properly 
getwd()
setwd("..")    # Dont execute two times
(path <- getwd())

airports <- read.csv("https://raw.githubusercontent.com/jpatokal/openflights/master/data/airports.dat", header = FALSE, na.strings=c("\\N",""), fileEncoding = "UTF-8")
colnames(airports) <- c("airportID", "name", "city", "country", "IATA", "ICAO",
                        "latitude", "longitude", "altitude", "timezone", "DST",
                        "tzFormat","typeAirport","Source")
airportsCanada <- airports[airports$country=="Canada",]

# We fill the missing IATA
airportsCanada$IATA <- as.character(airportsCanada$IATA) 
airportsCanada$IATA[is.na(airportsCanada$IATA)] <- substr(airportsCanada$ICAO[is.na(airportsCanada$IATA)],2,4) 
airportsCanada$IATA <- as.factor(airportsCanada$IATA)
airportsCanada <- subset(airportsCanada, select = -ICAO)
View(airportsCanada)


# install.packages("sp")
# install.packages("rgdal")
library(sp)
library(rgdal)
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
    c.PRENAME as provMerged
  from airportsCanada a 
  left join merged_prov c
  on a.airportID = c.airportID
  order by a.airportID")
airportsCanada <- data.frame(as.matrix(airportsCanada))

# We keep the province, and IATA for the dataset
provinceData <- subset(airportsCanada, select = c(IATA, provMerged ))
summary(provinceData)

# install.packages("plyr")
library(plyr)
provinceData <- rename(provinceData, c("provMerged"="province"))
summary(provinceData)

# We have created a dataset of the province of each airport
write.csv(provinceData, paste(path,"/Reference/province.csv",sep=""),row.names = FALSE, na = c("\\N",""),  fileEncoding = "UTF-8")


