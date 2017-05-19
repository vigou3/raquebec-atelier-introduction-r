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

# We keep only the routes from Canada 
routesCanada <- sqldf("
                      select *
                      from routes
                      where sourceAirportID in (select distinct airportID
                      from airportsCanada)
                      and destinationAirportID in (select distinct airportID
                      from airportsCanada)")
routesCanada  <- data.frame(as.matrix(routesCanada ))


write.csv(routesCanada, paste(path,"/Reference/RoutesModif.csv",sep=""),row.names = FALSE, fileEncoding = "UTF-8")
