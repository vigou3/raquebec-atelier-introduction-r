#
# Source code for the modification of the airport dataset
#

#
# This data is modified for a more simplify version of the complet CaseStudy. 
#

# Setting working directory properly 
getwd()
setwd("..")    # Dont execute two times
(path <- getwd())

# Import of the original data
airports <- read.csv("https://raw.githubusercontent.com/jpatokal/openflights/master/data/airports.dat", header = FALSE, na.strings=c("\\N",""), fileEncoding = "UTF-8")

# Setting name
colnames(airports) <- c("airportID", "name", "city", "country", "IATA", "ICAO",
                        "latitude", "longitude", "altitude", "timezone", "DST",
                        "tzFormat","typeAirport","Source")


# install.packages("sp")
# install.packages("rgdal")
library(sp)
library(rgdal)
tz_world.shape <- readOGR(dsn=paste(path,"/Reference/tz_world",sep=""),layer="tz_world")
unknown_tz <- airports[is.na(airports$tzFormat),c("airportID","name","longitude","latitude")]
sppts <- SpatialPoints(unknown_tz[,c("longitude","latitude")])
proj4string(sppts) <- CRS("+proj=longlat")
sppts <- spTransform(sppts, proj4string(tz_world.shape))
merged_tz <- cbind(unknown_tz,over(sppts,tz_world.shape))

# install.packages("sqldf")
library(sqldf)
airports <- sqldf("
                        select 
                        a.*, 
                        coalesce(a.tzFormat,b.TZID) as tzMerged
                        from airports a 
                        left join merged_tz b
                        on a.airportID = b.airportID
                        order by a.airportID")
airports <- data.frame(as.matrix(airports))

# Since the timezone, DST and city are now useless, we remove them from the dataset.
# Plus, we withdraw tzFormat because it's incomplet and we will use the tzmerge data to replace will a complete data. 
airports <- subset(airports, select = -c(tzFormat ))
summary(airports)

# install.packages("plyr")
library(plyr)
airports <- rename(airports, c("tzMerged"="tzFormat"))
summary(airports)

# We have fill all the missing tzFormat for the CaseStudyStudent document
write.csv(airports, paste(path,"/Reference/AirportModif.csv",sep=""),row.names = FALSE, fileEncoding = "UTF-8")

# In case of a student without Internet we have import the other data
