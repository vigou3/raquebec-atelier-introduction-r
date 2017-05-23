#
# Source code for the modification of the airport data set
#

#
# This data is modified for a more simplify version of the complet CaseStudy. 
#

# Setting working directory properly 
getwd()
setwd("..")    # Dont execute two times
(path <- getwd())



routes <- read.csv("https://raw.githubusercontent.com/jpatokal/openflights/master/data/routes.dat", header = FALSE, na.strings=c("\\N",""))
colnames(routes) <- c("airline","airlineID","sourceAirport","sourceAirportID",
                      "destinationAirport","destinationAirportID","codeshare",
                      "stops","equipment")

airports <- read.csv(paste(path,"/Reference/AirportModif.csv",sep=""), na.strings=c("\\N",""), fileEncoding = "UTF-8", comment = "#")
airportsCanada <- airports[airports$country=="Canada",]

# We keep only the routes from Canada 
routesCanada <- sqldf("
                      select *
                      from routes
                      where sourceAirportID in (select distinct airportID
                      from airportsCanada)
                      and destinationAirportID in (select distinct airportID
                      from airportsCanada)")
routesCanada  <- data.frame(as.matrix(routesCanada ))

# install.packages("sqldf")
library("sqldf")
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

# We write and CSV files for the routesCanada
write.csv(routesCanada, paste(path,"/Reference/RoutesModif.csv",sep=""), row.names = FALSE, fileEncoding = "UTF-8")

# We save the coordinate of the routes as an R object
save(routesCoord, file = paste(path,"/Reference/RoutesCoord.R",sep=""))
