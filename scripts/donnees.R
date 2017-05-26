### Emacs: -*- coding: utf-8; fill-column: 62; comment-column: 27; -*-
##
## Copyright (C) 2017 Vincent Goulet
##
## Ce fichier fait partie du projet «Introduction à R - Atelier
## du colloque R à Québec 2017»
## http://github.com/vigou3/raquebec-atelier-introduction-r
##
## Cette création est mise à disposition selon le contrat
## Attribution-Partage dans les mêmes conditions 4.0
## International de Creative Commons.
## http://creativecommons.org/licenses/by-sa/4.0/

###
### VECTEUR SIMPLE
###

## [Voir le fichier bases.R]

###
### MATRICE ET TABLEAU
###

## Une matrice est un vecteur avec un attribut 'dim' de
## longueur 2. La manière naturelle de créer une matrice est
## avec la fonction 'matrix'.
(x <- matrix(1:12, nrow = 3, ncol = 4)) # créer la matrice
length(x)                  # 'x' est un vecteur...
dim(x)                     # ... avec deux dimensions

## Les matrices sont remplies par colonne par défaut. Utiliser
## l'option 'byrow' pour remplir par ligne.
matrix(1:12, nrow = 3, byrow = TRUE)

## Indicer la matrice ou le vecteur sous-jacent est
## équivalent. Utiliser l'approche la plus simple selon le
## contexte.
x[1, 3]                    # l'élément en position (1, 3)...
x[7]                       # ... est le 7e élément du vecteur
x[1, ]                     # première ligne
x[, 2]                     # deuxième colonne
nrow(x)                    # nombre de lignes
dim(x)[1]                  # idem
ncol(x)                    # nombre de colonnes
dim(x)[2]                  # idem

## La fonction 'rbind' ("row bind") permet d'«empiler» des
## matrices comptant le même nombre de colonnes.
##
## De manière similaire, la fonction 'cbind' ("column bind")
## permet de concaténer des matrices comptant le même nombre de
## lignes.
##
## Utilisées avec un seul argument, 'rbind' et 'cbind' créent
## des vecteurs ligne et colonne, respectivement. Ceux-ci sont
## rarement nécessaires.
x <- matrix(1:12, 3, 4)    # 'x' est une matrice 3 x 4
y <- matrix(1:8, 2, 4)     # 'y' est une matrice 2 x 4
z <- matrix(1:6, 3, 2)     # 'z' est une matrice 3 x 2
rbind(x, 99)               # ajout d'une ligne à 'x'
rbind(x, y)                # fusion verticale de 'x' et 'y'
cbind(x, 99)               # ajout d'une colonne à 'x'
cbind(x, z)                # concaténation de 'x' et 'z'
rbind(x, z)                # dimensions incompatibles
cbind(x, y)                # dimensions incompatibles
rbind(1:3)                 # vecteur ligne
cbind(1:3)                 # vecteur colonne

## Un tableau (array) est un vecteur avec plus de deux
## dimensions. Quant au reste, la manipulation des tableaux
## est en tous points identique à celle des matrices. Ne pas
## oublier: les tableaux sont remplis de la première dimension
## à la dernière!
(x <- array(1:60, 3:5))    # tableau 3 x 4 x 5
length(x)                  # 'x' est un vecteur...
dim(x)                     # ... avec trois dimensions
x[1, 3, 2]                 # l'élément en position (1, 3, 2)...
x[19]                      # ... est le 19e élément du vecteur

## Le tableau ci-dessus est un prisme rectangulaire 3 unités
## de haut, 4 de large et 5 de profond. Indicer ce prisme avec
## un seul indice équivaut à en extraire des «tranches», alors
## qu'utiliser deux indices équivaut à en tirer des «carottes»
## (au sens géologique du terme). Il est laissé en exercice de
## généraliser à plus de dimensions...
x                          # les cinq matrices
x[, , 1]                   # tranches de haut en bas
x[, 1, ]                   # tranches d'avant à l'arrière
x[1, , ]                   # tranches de gauche à droite
x[, 1, 1]                  # carotte de haut en bas
x[1, 1, ]                  # carotte d'avant à l'arrière
x[1, , 1]                  # carotte de gauche à droite

###
### FACTEUR
###

## Les facteurs jouent un rôle important en analyse de
## données. surtout pour classer des données en diverses
## catégories. Les données d'un facteur devraient normalement
## afficher un fort taux de redondance.
##
## Reprenons l'exemple des diapositives.
(grandeurs <-
     factor(c("S", "S", "L", "XL", "M", "M", "L", "L")))
levels(grandeurs)          # les catégories
as.integer(grandeurs)      # représentation interne

## Dans le présent exemple, nous pourrions souhaiter que le
## fait que R reconnaisse le fait S < M < L < XL. C'est
## possible avec les facteurs *ordonnés*.
factor(c("S", "S", "L", "XL", "M", "M", "L", "L"),
       levels = c("S", "M", "L", "XL"),
       ordered = TRUE)

###
### LISTE
###

## La liste est l'objet le plus général en R. C'est un objet
## récursif qui peut contenir des objets de n'importe quel
## mode et longueur.
(x <- list(joueur = c("V", "C", "C", "M", "A"),
           score = c(10, 12, 11, 8, 15),
           expert = c(FALSE, TRUE, FALSE, TRUE, TRUE),
           niveau = 2))
length(x)                  # vecteur de quatre éléments...
mode(x)                    # ... de mode "list"

## Comme tout autre vecteur, une liste peut être concaténée
## avec un autre vecteur avec la fonction 'c'.
y <- list(TRUE, 1:5)       # liste de deux éléments
c(x, y)                    # liste de six éléments

## Pour extraire un élément d'une liste, il faut utiliser les
## crochets doubles [[ ]]. Les crochets simples [ ]
## fonctionnent aussi, mais retournent une sous liste -- ce
## qui est rarement ce que l'on souhaite.
x[[1]]                     # comparer ceci...
x[1]                       # ... avec cela
x[[1]][2]                  # 2e élément du 1er élément
x[[c(1, 2)]]               # idem, par indiçage récursif

## Les éléments d'une liste étant généralement nommés (c'est
## une bonne habitude à prendre!), il est souvent plus simple
## et sûr d'extraire les éléments d'une liste par leur
## étiquette avec l'opérateur $.
x$joueur                   # équivalent à x[[1]]
x$joueur[2]                # équivalent à x[[c(1, 2)]]
x[["expert"]]              # aussi valide, mais peu usité
x$level <- 1               # aussi pour l'affectation

###
### DATA FRAME
###

## Un data frame est une liste dont les éléments sont tous de
## même longueur. Il comporte un attribut 'dim', ce qui fait
## qu'il est représenté comme une matrice. Cependant, les
## colonnes peuvent être de modes différents.
data.frame(Noms = c("Pierre", "Jean", "Jacques"),
           Age = c(42, 34, 19),
           Fumeur = c(TRUE, TRUE, FALSE),
           stringsAsFactors = FALSE)

## R est livré avec plusieurs jeux de données.
data()                     # liste complète

## Création d'une copie du jeu de données 'USArrests' dans
## l'espace de travail.
data(USArrests)

## Analyse succincte de l'objet.
mode(USArrests)            # un data frame est une liste...
length(USArrests)          # ... de quatre éléments...
class(USArrests)           # ... de classe 'data.frame'
dim(USArrests)             # dimensions implicites
names(USArrests)           # titres des colonnes
row.names(USArrests)       # titres des lignes
USArrests[, 1]             # première colonne
USArrests$Murder           # idem, plus simple
USArrests[1, ]             # première ligne

## La fonction 'subset' permet d'extraire des lignes et des
## colonnes d'un data frame de manière très intuitive.
##
## Par exemple, nous pouvons extraire ainsi le nombre
## d'assauts dans les états comptant un taux de meurtre
## supérieur à 10.
subset(USArrests, Murder > 10, select = Assault)
