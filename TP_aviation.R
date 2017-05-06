library(readr)


#### Étape 1: Extraction des données

# data principal
airport_data <- read_csv("C:/Users/David/Desktop/airport_data.txt", col_names = FALSE, col_types = cols(X13 = col_skip(), X14 = col_skip()))
# Ajout nom colonne
colnames(airport_data) <- c("Airport ID", "Name", "City", "Country", "IATA", "ICAO", "Latitude", "Longitude", "Altitude", "TimeZone", "DST", "Tz database timezone")

# Extraction des aéroports canadiens
airport_canada <- airport_data[airport_data$Country == "Canada", ]
View(airport_canada)


#### Étape 2: Représentation des données

# Deux options:

## 1)

library(maps)
#Carte plus précise
library(mapdata)

#3ieme est YUL - Aéroport de MTL
# On pourrait demander une liste de ville : Montréal, QBC, Ottawa, Toronto, ...
gps_montreal <- airport_canada[airport_canada$City == "Montreal", c("Longitude", "Latitude")][3,]


map("worldHires", "Canada", fill = T, col = 'antiquewhite')
map.scale(relwidth = 0.3)
points(gps_montreal, pch = 16)
text(gps_montreal, labels = "Montreal", pos = 3)


## 2)
library(cartography)
# Plus difficile
# ...


# Simulation des vols ?
