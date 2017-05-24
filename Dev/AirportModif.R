# coding: utf-8
# Source code for the modification of the airport dataset
# Authors: David Beauchemin & Samuel Cabral Cruz

#
# This data is modified for a more simplify version of the complet CaseStudy. 
#

# Setting working directory properly 
getwd()
setwd("..")    # Dont execute two times
(path <- getwd())

# Import of the original data
airports <- read.csv("https://raw.githubusercontent.com/jpatokal/openflights/master/data/airports.dat"
                     , header = FALSE, na.strings=c("\\N",""), fileEncoding = "UTF-8")

# Setting name
colnames(airports) <- c("airportID", "name", "city", "country", "IATA", "ICAO",
                        "latitude", "longitude", "altitude", "timezone", "DST",
                        "tzFormat","typeAirport","Source")


# We fill the missing IATA for canada
airports$IATA <- as.character(airports$IATA) 
airports$IATA[is.na(airports$IATA)] <- substr(airports$ICAO[is.na(airports$IATA)],2,4) 
airports$IATA <- as.factor(airports$IATA)
airports <- subset(airports, select = -ICAO)



# Adding the number of arrivalFlights for each airports
routesCanada <- read.csv(paste(path,"/Reference/RoutesModif.csv",sep=""),  na.strings=c("\\N",""), 
                         fileEncoding = "UTF-8", comment = "#")

arrivalFlights <- table(routesCanada$destinationAirport)
arrivalFlights <- data.frame(arrivalFlights)
colnames(arrivalFlights) <- c("IATA","totalFlights")
# On joint les données sur l'achalandage aux aéroports canadiens appropriés
airports<- merge(airportsCanada, arrivalFlights, by.x = "IATA", by.y = "IATA")



# We have fill all the missing tzFormat for the CaseStudyStudent document
write.csv(airports, paste(path,"/Reference/AirportModif.csv",sep=""),row.names = FALSE, fileEncoding = "UTF-8", na = c("\\N",""))

# In case of a student without Internet we have import the other data
