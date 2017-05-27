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



# Adding the number of arrivalFlights for each airports
routesCanada <- read.csv("https://raw.githubusercontent.com/jpatokal/openflights/master/data/routes.dat", 
                                   header = FALSE, na.strings=c("\\N",""))
colnames(routesCanada) <- c("airline","airlineID","sourceAirport","sourceAirportID",
                      "destinationAirport","destinationAirportID","codeshare",
                      "stops","equipment")

arrivalFlights <- table(routesCanada$destinationAirport)
arrivalFlights <- data.frame(arrivalFlights)
colnames(arrivalFlights) <- c("IATA","totalFlights")

# Data on ridership are attached to appropriate Canadian airports
airports<- merge(airports, arrivalFlights, by.x = "IATA", by.y = "IATA", all.x = TRUE)

airpotsCanada <- subset(airports, country == "Canada")

write.csv(airports, paste(path,"/data/AirportModif.csv",sep=""),row.names = FALSE, fileEncoding = "UTF-8", na = c("\\N",""))

# In case of a student without Internet we have import the other data
