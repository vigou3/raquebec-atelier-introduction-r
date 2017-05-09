library(geosphere)

#Question 1 - Extraction, traitement, visualisation et analyse des données

#1.1 - Extraire les bases de données airports.dat et routes.dat
airports <- read.csv("https://raw.githubusercontent.com/jpatokal/openflights/master/data/airports.dat", header = FALSE, na.strings=c('\\N',''))
routes <- read.csv("https://raw.githubusercontent.com/jpatokal/openflights/master/data/routes.dat", header = FALSE, na.strings=c('\\N',''))

#1.2 - Attribuer des noms aux colonnes du jeu de données en vous fiant à l'information disponible sur le site
colnames(airports) <- c("airportID", "name", "city", "country", "IATA", "ICAO",
                        "latitude", "longitude", "altitude", "timezone", "DST",
                        "tzFormat","typeAirport","Source")
colnames(routes) <- c("airline","airlineID","sourceAirport","sourceAirportID",
                      "destinationAirport","destinationAirportID","codeshare",
                      "stops","equipment")

#1.3 - Nettoyer le jeu de données en ne conservant que les données relatives au Canada
airports <- airports[airports$country=='Canada',]

#1.4 - Extraire des informations générales sur la distribution des variables présentent dans le jeu de données 
# et vous informer sur la signification de ces dernières ainsi que sur les différentes modalités quelles peuvent 
# prendre
head(airports)
summary(airports)
nbAirportCity <- table(as.character(airports$city))
(nbAirportCity <- sort(nbAirportCity,decreasing=TRUE))[1:10]

#1.5 - Corriger les modalités des variables et faire une sélection des variables qui vous semble utiles 
# pour le reste du traitement
#Nous observons que les variables typeAirport et Source ne sont d'aucune utilité dans la situation présente
#compte tenu que nous n'utilisons que l'information sur le transport par voies aériennes.
#Un raisonnement similaire est applicable pour la variable country qui ne possèdera que la modalité Canada
airports <- airports[,-match(c("country","typeAirport","Source"),colnames(airports))]
#Nous pouvons aussi constater que 27 aéroports ne possèdent aucun code IATA.
airports[is.na(airports$IATA),c("airportID","name","IATA","ICAO")]
#Cependant, toutes ces aéroports possèdent un code ICAO bien défini ce qui permettra d'attribuer une valeur
#par défaut. Une autre possibilité aurait été de simplement ignorer ces aéroports dans le reste de l'analyse.
#Cette approximation ne semble pas trop contraignante compte tenu du fait que les trois derniers caractères
#du code ICAO correspondent au code IATA dans 82% des cas.
sum(airports$IATA==substr(airports$ICAO,2,4),na.rm = TRUE)/sum(!is.na(airports$IATA))
#Nous modifions donc la variable IATA et nous nous débarasserons de la variable ICAO
airports$IATA <- as.character(airports$IATA)
airports$IATA[is.na(airports$IATA)] <- substr(airports$ICAO[is.na(airports$IATA)],2,4)
airports$IATA <- as.factor(airports$IATA)
airports <- airports[,-match("ICAO",colnames(airports))]
#Finalement, nous voyons qu'il semble y avoir une quarantaine d'aéroport pour lesquels nous n'avons pas
# d'information sur le fuseau horaire
missingTZ <- airports[is.na(airports$timezone),]
#Puisque le fuseau horaire ne dépend que de la position géographique, tentons de voir s'il est possible 
# de trouver des aéroports proches de c'est derniers pour en déduire les informations
(x <- missingTZ$longitude)
(y <- missingTZ$latitude)
knownTZ <- airports[!is.na(airports$timezone),]
apply(cbind(x,y),1, function(x) min(distGeo(x,cbind(knownTZ$longitude,knownTZ$latitude))/1000))

summary(airports)

sapply(x,function(x) min(abs(x-knownTZ$longitude)))




routes <- routes[!is.na(match(routes$sourceAirportID,airports$airportID)) &
                   !is.na(match(routes$destinationAirportID,airports$airportID)),]
#Produira le même résultat
#routes <- routes[!is.na(match(routes$sourceAirport,airports$IATA)) &
#                 !is.na(match(routes$destinationAirport,airports$IATA)),]


summary(routes)
head(routes)