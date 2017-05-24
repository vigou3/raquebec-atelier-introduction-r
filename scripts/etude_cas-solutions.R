## Copyright (C) 2017 David Beauchemin, Samuel Cabral Cruz
##
## Ce fichier fait partie du projet «Introduction à R - Atelier
## du colloque R à Québec 2017»
## http://github.com/vigou3/raquebec-atelier-introduction-r
##
## Cette création est mise à disposition selon le contrat
## Attribution-Partage dans les mêmes conditions 4.0
## International de Creative Commons.
## http://creativecommons.org/licenses/by-sa/4.0/

## Initialisation de l'amorce du générateur de nombres aléatoires.
set.seed(31459)

## Importation des données dans l'espace de travail.
airports <- read.csv(paste(path,"/Reference/AirportModif.csv",sep=""),
                     comment.char = "#",
                     as.is = c(2, 3, 5),
                     na.strings = c("\\N", ""),
                     fileEncoding = "UTF-8")
province <- read.csv(paste(path,"/Reference/province.csv",sep=""),
                     comment.char = "#",
                     as.is = 1,
                     na.strings = c("\\N", ""),
                     fileEncoding = "UTF-8")

## Exercice 1

### 1.1 Extraire les données des aéroports canadiens par indicage du
###     data frame
airportsCanada <- airports[airports$country=="Canada", ]

### 1.2 Extraire les données des aéroports canadiens à l'aide de la
###     fonction 'subset'.
airportsCanada2 <- subset(airports, country == "Canada")


## Exercice 2

### 2.1 À partir des données des aéroports canadiens, créer un tableau
###     de fréquence du nombre d'aéroports par ville à l'aide de la
###     fonction 'table'.
nbAirportCity <- table(airportsCanada$city)

### 2.2 Déterminer les cinq villes canadiennes comptant le plus
###     d'aéroports.
head(sort(nbAirportCity, decreasing = TRUE), 5)


## Exercice 3

### 3.1 Déterminer le nombre de codes IATA manquant dans les données
###     des aéroports canadiens à l'aide de la fonction 'sum'.
sum(is.na(airportsCanada$IATA))

### 3.2 Répéter l'exercice 3.1 avec la fonction 'length'.
length(airportsCanada$IATA[is.na(airportsCanada$IATA)])


## Exercice 4

### Ajouter le code de province aux données d'aéroports canadiens en
### les fusionnant avec les données 'province' par le prédicat IATA.
### Utiliser la fonction 'merge'.
airportsCanada<- merge(airportsCanada, province, by = "IATA")


## Exercice 5

### Écrire une fonction 'listeIATA' qui prend en arguments un code
### IATA de départ et un code IATA d'arrivée, et qui retourne dans une
### liste les informations suivantes:
###
### 1. 'depart', le code IATA de départ;
### 2. 'arrival', le code IATA d'arrivée;
### 3. 'route', une chaine de caractères formée des deux codes IATA
###    séparés par un trait d'union.
###
### Utiliser la fonction 'paste' pour créer la chaine de caractères.
listeIATA <- function(depart, arrival)
{
    list(depart = depart,
         arrival = arrival,
         route = paste(depart, arrival, sep = "-"))
}
listeIATA("YUL", "YYQ")


## Exercice 6

### Écrire une fonction 'shippingCost' qui prend en argument une
### distance et un poids, et qui retourne le coût de la livraison selon
### la formule suivante:
###
###   coût = poids * indicePoids + distance * indiceDistance.
###
### Utiliser un indice de poids de 0.7 et un indice de distance de
### 0.02.
###
### La fonction devrait afficher un message d'erreur lorsque le poids
### dépasse 30 kg.
shippingCost <- function(distance, weight)
{
     if (weight > 30)
     {
         stop("maximum allowed weight is 30 kg")
     }

     0.7 * weight + 0.02 * distance
}
shippingCost(1, 10)
shippingCost(100, 31)


## Exercice 7
### 7.1 Dessiner un nuage de points de la fréquence des routes
###     aériennes entrantes pour chaque aéroport à l'aide de la
###     fonction 'plot'.
plot(airportsCanada$totalFlights)

### 7.2 Représenter la distribution de fréquence du nombre de routes
###     aériennes entrantes à d'un histograme.
hist(airports$totalFlights)

### 7.3 Tracer la fonction de répartition empirique du nombre de
###     routes aériennes entrantes. Utiliser la fonction 'ecdf'.
plot(ecdf(airports$totalFlights))


## Exercices 8

### Tracer une courbe du coût d'un envoi. Le titre du graphique doit
### être «Coût d'envoi» et la légende de l'ordonnée, «Coût» et la 
### légenre de l'abscisse, «Distance».
###
### Utiliser les données simulées suivantes.
cost <- sort(runif(100, min = 5, max = 50))
distance <- sort(rlnorm(100, 2, 1.1))
plot(distance, cost,  main = "Coût d'envoi", ylab = "Coût", xlab = "Distance")


## Exercices 9

### Tracer un graphique du coût d'un envoi en fonction du poids du
### colis et de la distance à parcourir. Utiliser la fonction
### 'plot3d' du package "plot3D".
###
### Utiliser les données simulées suivantes.
weight <- runif(1000, 1, 30)
distance <- rlnorm(1000, 5, 1.1)
cost <- weight * 0.7 + distance * 0.02

pairs(~ cost + weight + distance)
# install.packages("plot3D")
library("plot3D")
plot3d(weight, distance, cost)


## Exercice 10

### Calculer un modèle de régression liant le coût d'un envoi au poids
### du colis et à la distance à parcourir.
###
### Utiliser les données simulées suivantes.
weight <- runif(1000, 1, 30)
distance <- rlnorm(1000, 5, 1.1)
cost <- rgamma(1000, 35, 1)

fit <- lm(cost ~ distance + weight)
summary(fit)
plot(fit)


## Exercices 11 ####

### Ajuster une loi gamma à la distribution des coûts par la méthode
### du maximum de vraisemblance. Utiliser la fonction 'optim' pour
### minimiser la log-vraisemblance négative
###
###  - sum(log(dgamma(x, shape, rate))).
###
### Utiliser les données simulées suivantes.
cost <- rgamma(1000, 35, 1)

loglik <- function(x, p)
     - sum(dgamma(x, p[1], p[2], log = TRUE))
optim(c(1, 1), loglik, x = cost)


## Exercices 12

### Ajuster des lois gamma et log-normale à la distribution des poids
### des colis à l'aide de la fonction 'fitdistr' du paquetage MASS.
###
### Importer et utiliser les données suivantes.
compData <- read.csv("data/benchmark.csv")
colnames(compData) <- c("weight", "distance", "cost")

library("MASS")
(fit.gamma <- fitdistr(compData$weight, "gamma"))
(fit.lnorm <- fitdistr(compData$weight, "lognormal"))


## Exercices 13

### Simuler, à l'aide la fonction 'sample', la destination de 100
### envois de colis à partir de l'aéroport Montréal-Trudeau (YUL) en
### tenant compte de la fréquence relative des différentes routes
### aériennes.
###
### Utiliser les données suivantes.
aeroports <- c("YYZ", "YQZ", "YKZ", "YYC", "YWF", "YAM",
               "YBC", "YPA", "YOW", "YZR", "YQY")
freq <- c(4, 23, 12,  7, 22, 18, 12,  7, 18,  6,  2)

sample(aeroports, size = 100, prob = freq, replace = TRUE)


## Exercices 14

### Simuler les poids et les distances à parcourir de 100 envois de
### colis à partir de l'aéroport Montréal-Trudeau (YUL).
###
### La distribution des poids est une loi uniforme sur l'intervalle
### (1, 30). Celle des distances est une loi log-normale de paramètres
### 5 et 1.1.
###
### Conserver les valeurs simulées dans des objets weightSimul et
### distanceSimul.
weightSimul <- runif(100, 1, 30)
distanceSimul <- rlnorm(100, 5, 1.1)


## Exercices 15

### Déterminer le coût de chacun des envois pour les données simulées
### précédemment à partir de la fonction de coût suivante:
###
###   coût = poids * 0.7 + distance * 0.02
cost <- weightSimul * 0.7 + distanceSimul * 0.02
