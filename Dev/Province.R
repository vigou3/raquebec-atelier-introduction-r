#
# Source code for the creation of province dataset
#


# Setting working directory properly 
getwd()
setwd("..")    # Dont execute two times
(path <- getwd())

airports <- read.csv("https://raw.githubusercontent.com/jpatokal/openflights/master/data/airports.dat", header = FALSE, na.strings=c("\\N",""), fileEncoding = "UTF-8")
colnames(airports) <- c("airportID", "name", "city", "country", "IATA", "ICAO",
                        "latitude", "longitude", "altitude", "timezone", "DST",
                        "tzFormat","typeAirport","Source")
airportsCanada <- airports[airports$country=="Canada",]

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
# Since the timezone, DST and city are now useless, we remove them from the dataset.
# Plus, we withdraw tzFormat because it's incomplet and we will use the tzmerge data to replace will a complete data. 
provinceData <- subset(airportsCanada, select = c(city, provMerged ))
summary(provinceData)

# install.packages("plyr")
library(plyr)
provinceData <- rename(provinceData, c("provMerged"="province"))
summary(provinceData)

# We have created a dataset of the province of each airport
write.csv(provinceData, paste(path,"/Reference/province.csv",sep=""),row.names = FALSE, na = c("\\N",""),  fileEncoding = "UTF-8")


