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
airlines <- read.csv("https://raw.githubusercontent.com/jpatokal/openflights/master/data/airlines.dat", header = FALSE, na.strings=c("\\N",""))

colnames(routes) <- c("airline","airlineID","sourceAirport","sourceAirportID",
                      "destinationAirport","destinationAirportID","codeshare",
                      "stops","equipment")
colnames(airlines) <- c("airlineID","name","alias","IATA","ICAO","Callsign","Country","Active")

write.csv(routes, paste(path,"/Reference/RoutesModif.csv",sep=""),row.names = FALSE, fileEncoding = "UTF-8")
write.csv(airlines, paste(path,"/Reference/AirlinesModif.csv",sep=""),row.names = FALSE, fileEncoding = "UTF-8")
