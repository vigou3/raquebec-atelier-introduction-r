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

## Initialisation de l'amorce du générateur de nombres aléatoires.
set.seed(31459)

## Importation des données dans l'espace de travail.
airports <- read.csv("data/AirportModif.csv",
                     comment.char = "#",
                     as.is = c(2, 3, 5),
                     na.strings = c("\\N", ""),
                     fileEncoding = "UTF-8")
province <- read.csv("data/province.csv",
                     comment.char = "#",
                     as.is = 1,
                     na.strings = c("\\N", ""),
                     fileEncoding = "UTF-8")

## Exercice 1

### 1.1 Extraire les données des aéroports canadiens par indicage du
###     data frame avec [ ].


### 1.2 Répéter l'exercice 1.1 avec la fonction 'subset'.



## Exercice 2

### 2.1 À partir des données des aéroports canadiens, créer un tableau
###     de fréquence du nombre d'aéroports par ville à l'aide de la
###     fonction 'table'.


### 2.2 Déterminer les cinq villes canadiennes comptant le plus
###     d'aéroports.



## Exercice 3

### 3.1 Déterminer le nombre de codes IATA manquants dans les données
###     des aéroports canadiens à l'aide de la fonction 'sum'.


### 3.2 Répéter l'exercice 3.1 avec la fonction 'length'.



## Exercice 4

### Ajouter le code de province aux données d'aéroports canadiens en
### les fusionnant avec les données 'province' par le prédicat IATA.
### Utiliser pour ce faire la fonction 'merge'.



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

}



## Exercice 6

### Écrire une fonction 'shippingCost' qui prend en arguments une
### distance et un poids, et qui retourne le coût de la livraison
### calculé avec la formule suivante:
###
###   coût = poids * indicePoids + distance * indiceDistance.
###
### Utiliser un indice de poids de 0.7 et un indice de distance de
### 0.02.
###
### La fonction devrait afficher un message d'erreur lorsque le poids
### dépasse 30 kg.



## Exercice 7

### 7.1 La variable 'totalFlights' du jeu de données contient le
###     nombre de routes aériennes entrantes dans un aéroport. Tracer
###     un nuage de points de la fréquence de ces routes à l'aide de
###     la fonction 'plot'.


### 7.2 Représenter la distribution de fréquence du nombre de routes
###     aériennes entrantes à l'aide d'un histograme. Utiliser la
###     fonction 'hist'.


### 7.3 Tracer la fonction de répartition empirique du nombre de
###     routes aériennes entrantes. Utiliser la fonction 'ecdf'.



## Exercice 8

### Tracer une courbe du coût d'un envoi. Le titre du graphique doit
### être «Coût d'envoi», la légende de l'ordonnée «Coût» et la
### légenre de l'abscisse, «Distance».
###
### La rubrique d'aide de la fonction 'par' fournit la liste de tous
### les paramètres graphiques.
###
### Utiliser les données simulées suivantes.
cost <- runif(100, min = 5, max = 50)
distance <- rlnorm(100, 2, 1.1)


## Exercice 9

### Tracer une série de graphiques des relations deux à deux entre le
### coût d'un envoi, le poids du colis et la distance à parcourir.
### Utiliser pour ce faire la fonction 'pairs'.
###
### Utiliser les données simulées suivantes.
weight <- runif(1000, 1, 30)
distance <- rlnorm(1000, 5, 1.1)
cost <- weight * 0.7 + distance * 0.02



## Exercice 10

### Calculer un modèle de régression avec la fonction 'lm' liant le
### coût d'un envoi au poids du colis et à la distance à parcourir.
###
### Utiliser les données simulées suivantes.
weight <- runif(1000, 1, 30)
distance <- rlnorm(1000, 5, 1.1)
cost <- rgamma(1000, 35, 1)



## Exercice 11

### Ajuster une loi gamma à la distribution des coûts par la méthode
### du maximum de vraisemblance. Utiliser la fonction 'optim' pour
### minimiser la log-vraisemblance négative
###
###  - sum(log(dgamma(x, shape, rate))).
###
### Utiliser les données simulées suivantes.
cost <- rgamma(1000, 35, 1)



## Exercice 12

### Ajuster des lois gamma et log-normale à la distribution des poids
### des colis à l'aide de la fonction 'fitdistr' du paquetage MASS.
### (Ce paquetage est livré avec R, mais il n'est pas chargé par
### défaut.)
###
### Importer et utiliser les données suivantes.
compData <- read.csv("data/benchmark.csv")
colnames(compData) <- c("weight", "distance", "cost")



## Exercice 13

### Simuler, à l'aide la fonction 'sample', la destination de 100
### envois de colis à partir de l'aéroport Montréal-Trudeau (YUL) en
### tenant compte de la fréquence relative des différentes routes
### aériennes.
###
### Utiliser les données suivantes.
aeroports <- c("YYZ", "YQZ", "YKZ", "YYC", "YWF", "YAM",
               "YBC", "YPA", "YOW", "YZR", "YQY")
freq <- c(4, 23, 12,  7, 22, 18, 12,  7, 18,  6,  2)

## Exercice 14

### Simuler les poids et les distances à parcourir de 100 envois de
### colis à partir de l'aéroport Montréal-Trudeau (YUL).
###
### La distribution des poids est une loi uniforme sur l'intervalle
### (1, 30). Celle des distances est une loi log-normale de paramètres
### 5 et 1.1.
###
### Conserver les valeurs simulées dans des objets weightSimul et
### distanceSimul.



## Exercice 15

### Déterminer le coût de chacun des envois pour les données simulées
### précédemment à partir de la fonction de coût suivante:
###
###   coût = poids * 0.7 + distance * 0.02
