### Emacs: -*- coding: utf-8; fill-column: 62; comment-column: 27; -*-
##
## Copyright (C) 2017 Vincent Goulet, David Beauchemin, Samuel Cabral Cruz
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
### BIBLIOTHÈQUE ET PAQUETAGES
###

## Liste des paquetages chargés dans la session de travail
## courante.
search()

## Liste des bibliothèques parcourues par R
.libPaths()

## Liste des paquetages de la bibliothèque de base chargés par
## défaut au démarrage de R.
options("defaultPackages")

## Chargement d'un paquetage de la bibliothèque dans la
## session de travail.
library(MASS)
search()

## Installation d'un paquetage depuis le miroir canadien de
## CRAN.
install.packages(actuar, repos = "http://cran.ca.r-project.org")

## L'installation d'un paquetage ne le charge pas dans la
## session de travail.
library(actuar)
search()
