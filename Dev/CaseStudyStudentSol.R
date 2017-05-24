##
## Copyright (C) 2017 David Beauchemin, Samuel Cabral Cruz, Vincent Goulet
##
## Ce fichier fait partie du projet «Introduction à R - Atelier
## du colloque R à Québec 2017»
## http://github.com/vigou3/raquebec-atelier-introduction-r
##
## Cette création est mise à disposition selon le contrat
## Attribution-Partage dans les mêmes conditions 4.0
## International de Creative Commons.
## http://creativecommons.org/licenses/by-sa/4.0/

#
# caseStudyStudentSolution
#


#### Setting working directory properly ####
getwd()
setwd("..")
(path <- getwd())
set.seed(31459)

#### Import data ####
airports <- read.csv(paste(path,"/Reference/AirportModif.csv",sep=""), comment = "#",
                     as.is = c(2, 3, 5), na.strings=c("\\N",""), fileEncoding = "UTF-8")
province <- read.csv(paste(path,"/Reference/province.csv",sep=""), na.strings=c("\\N",""),
                     as.is = 1, fileEncoding = "UTF-8", comment = "#")

## Exercice 1 ####
# 1.1 À l'aide de l'indicage extraire toutes les aéroports canadiens
airportsCanada <- airports[airports$country=="Canada",]

# 1.2 À l'aide de la fonction R subset, extraire les aéroports canadiens
airportsCanada2 <- subset(airports,country == "Canada")

## Exercice 2 ####
# 2.1 À l'aide de la fonction R table, créé une table du nombre d'aéroports par ville.
nbAirportCity <- table(airportsCanada$city)
# 2.2 Déterminer les villes avec le plus d'aéroport au Canada à l'aide de la fonction R sort.
(nbAirportCity <- sort(nbAirportCity,decreasing=TRUE))[1:10]

## Exercice 3 ####
# 3.1 À l'aide de la fonction R lenght, déterminer le nombre de IATA manquant dans airportsCanada.
length(airportsCanada$IATA[is.na(airportsCanada$IATA)])
# 3.2 Faire le même exercice mais avec la fonction R sum.
sum(is.na(airportsCanada$IATA))

## Exercice 4 ####
# À l'aide de la fonction R merge, joindre les aéroports canadien à leur province adéquate par le prédicat IATA.
airportsCanada<- merge(airportsCanada, province, by.x = "IATA", by.y = "IATA")

## Exercice 5 ####
# Écrire une fonction qui retourne dans une liste les informations suivantes:
# Le sourceIATA
# Le destIATA
# À l'aide de la fonction R paste, la concaténation des deux chaines de caractère
listeIATA <- function(sourceIATA, destIATA)
{
     listeIATA <- list()
     listeIATA$source <- sourceIATA
     listeIATA$dest <- destIATA
     listeIATA$conca <- paste(sourceIATA, destIATA)
     listeIATA
}
listeIATA("YUL", "YYQ")

## Exercice 6 ####
# Écrire une fonction qui prend en argument une distance et un poids et qui retourne le prix de la
# livraison selon la formule suivante : prix = poids * indicePoids + distance * indiceDistance.
# De plus, assurer vous que le poids ne dépasse pas les 30 Kg, afficher le message suivant:
# "Le poids doit être inférieur à 30 Kg".
# Notes: l'indice de poids est de 0.7 et l'indice de distance est de 0.02
coutLivraison <- function(distance, poids)
{
     if(poids > 30)
     {
          stop("Le poids doit être inférieur à 30 Kg")
     }
     indicePoids <- 0.7
     indiceDistance <- 0.02

     prix <- poids * indicePoids + distance * indiceDistance
     prix
}
coutLivraison(1, 10)
coutLivraison(100, 31)

## Exercices 7 ####

# 7.1 À l'aide de la fonction R plot dessiner un nuage de point de la fréquence des voies aériennes
# entrantes pour chaque aéroport
plot(airports$totalFlights)

# 7.2 À l'aide de la fonction R hist dessiner un histograme à bande.
hist(airports$totalFlights)

# 7.3 À l'aide de la fonction R ecdf ainsi que de la fonction R plot dessiner la fonction de
# répartition.
plot(ecdf(airports$totalFlights))

## Exercices 8 ####
# À l'aide de la fonction R plot dessiner la courbe des prix. De plus, votre graphique doit comporter
# les informations suivantes:
# Titre du graphique : "Courbe des prix"
# Titres de l'axe des y (verticale) : Prix
# Donnée à votre disposition :
données <- sort(runif(100, min = 5, max = 100))

plot(données, main = "Courbe des prix", ylab = "Prix")

## Exercices 9 ####
# À l'aide de la fonction R plot3d dessiner un graphique du prix et de la distance par rapport au prix.
# Autrement dit, le poids en x, la distance en y et le prix en z.
# Données à votre disposition:
poids <- runif(1000, 1, 30)
distance <- rlnorm(1000, 5, 1.1)
prix <- rgamma(1000, 35, 1)

plot3d(poids, distance, prix)

## Exercice 10 ####
# À l'aide de la fonction R lm déterminer une droite de régression du prix ~ (en fonction de)
# la distance et du poids.
# Données à votre disposition:
poids <- runif(1000, 1, 30)
distance <- rlnorm(1000, 5, 1.1)
prix <- rgamma(1000, 35, 1)

lm(prix ~ distance + poids)

## Exercices 11 ####
# À l'aide de la fonction R optim, déterminer les paramètres de la fonction de densité des prix.
# Autrement dit, on cherche à optimiser la fonction : - sum ( log(dgamma(prix, param1, param2)))
fct <- function(prix, param)
{
     - sum(dgamma(prix, param[1], param [2], log = TRUE))
}
optim(c(1,1), function(param) fct(prix, param))

## Exercices 12 ####
# À l'aide de la fonction R fitdistr du package MASS, déterminer les paramètres des densités
# "lognormal" et "gamma" par rapport au poids
# Données à votre disposition :
compData <- read.csv(paste(path,"/Reference/benchmark.csv",sep="" ))
colnames(compData) <- c("weight","distance","price")
# install.packages("MASS")
library("MASS")
(fit.gamma <- fitdistr(compData$weight, "gamma"))
(fit.lognormal <- fitdistr(compData$weight, "lognormal"))

## Exercices 13 ####
# À l'aide de la fonction R sample simuler la destination de 100 envoie de colis à partir de "YUL".
# Données à votre diposition:
aeroports <- c("YYZ", "YQZ", "YKZ", "YYC", "YWF", "YAM", "YBC", "YPA", "YOW", "YZR", "YQY")
frequence <- c(4, 23, 12,  7, 22, 18, 12,  7, 18,  6,  2)
sample(aeroports, size = 100, prob = frequence, replace = TRUE)

## Exercices 14 ####
# À l"aide des fonctions R runif et rlnorm simuler des poids et des distances de 100 envoie des colis
# à partir de "YUL" et affecter les simulations aux variables respectives poidsSimul et distancesSimul.
# Notes:
# - Pour la simulation runif utiliser les paramètres 1 et 30.
# - Pour la simulation rlnorm utiliser les paramètres 5 et 1.1.
poidsSimul <- runif(100, 1, 30)
distancesSimul <- rlnorm(100, 5, 1.1)

## Exercices 15 ####
# À l'aide des données simulées précédaments déterminer le prix pour chacun des envoies de colis.
# Utiliser la fonction de prix suivantes : Prix = poids * 0.7 + distance * 0.02
Prix <- poidsSimul * 0.7 + distancesSimul * 0.02
