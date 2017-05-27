

(path <- paste(getwd(),"..",sep = "/"))


# Extraction of airports.dat 
airports <- read.csv("https://raw.githubusercontent.com/jpatokal/openflights/master/data/airports.dat",
                     header = FALSE, na.strings=c("\\N",""))
colnames(airports) <- c("airportID", "name", "city", "country", "IATA", "ICAO",
                        "latitude", "longitude", "altitude", "timezone", "DST",
                        "tzFormat","typeAirport","Source")

# Number of tzformat missing
length(airports$tzFormat[is.na(airports$tzFormat)])

# We use spp shape of the world TZ to fill the missing value
# install.packages("sp")		
# install.packages("rgdal")		
library(sp)		
library(rgdal)		
tz_world.shape <- readOGR(dsn=paste(path,"/ref/tz_world",sep=""),layer="tz_world")	
unknown_tz <- airports[is.na(airports$tzFormat),c("airportID","name","longitude","latitude")]		
sppts <- SpatialPoints(unknown_tz[,c("longitude","latitude")])		
proj4string(sppts) <- CRS("+proj=longlat")		
sppts <- spTransform(sppts, proj4string(tz_world.shape))		
merged_tz <- cbind(unknown_tz,over(sppts,tz_world.shape))		

# install.packages("sqldf")		
library(sqldf)		
airports <- sqldf("select 		
                   a.*, 		
                   coalesce(a.tzFormat,b.TZID) as tzMerged		
                   from airports a 		
                   left join merged_tz b		
                   on a.airportID = b.airportID		
                   order by a.airportID")		
airports <- data.frame(as.matrix(airports))
airports <- subset(airports, select = -tzFormat)

# install.packages("plyr")
library(plyr)
airports <- rename(airports, "tzMerged"="tzFormat")

# Final missing value
length(airports$tzFormat[is.na(airports$tzFormat)])
