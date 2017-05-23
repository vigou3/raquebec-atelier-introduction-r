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
### COMMANDES R
###

## Les expressions entrées à la ligne de commande sont
## immédiatement évaluées et le résultat est affiché à
## l'écran, comme avec une grosse calculatrice.
1                          # une constante
(2 + 3 * 5)^2/7            # expression mathématique
exp(3)                     # fonction exponentielle
sin(pi/2) + cos(pi/2)      # fonctions trigonométriques
gamma(5)                   # fonction gamma

## Lorsqu'une expression est syntaxiquement incomplète,
## l'invite de commande change de '> ' à '+ '.
2 -                        # expression incomplète
5 *                        # toujours incomplète
3                          # complétée

## Taper le nom d'un objet affiche son contenu. Pour une
## fonction, c'est son code source qui est affiché.
pi                         # constante numérique intégrée
letters                    # chaîne de caractères intégrée
LETTERS                    # version en majuscules
rnorm                      # fonction

###
### EXEMPLE DE SESSION DE TRAVAIL
###
### (Inspiré de l'annexe A du manuel «An Introduction to R», R
### Core Team, 2017.)
###

## Générer deux vecteurs de nombres pseudo-aléatoires issus
## d'une loi normale centrée réduite.
x <- rnorm(50)
y <- rnorm(x)

## Graphique des couples (x, y).
plot(x, y)

## Graphique d'une approximation de la densité du vecteur x.
plot(density(x))

## Générer la suite 1, 2, ..., 10.
1:10

## La fonction 'seq' peut générer des suites plus générales.
seq(from = -5, to = 10, by = 3)
seq(from = -5, length = 10)

## La fonction 'rep' répète des valeurs.
rep(1, 5)          # répéter 1 cinq fois
rep(1:5, 5)        # répéter le vecteur 1,...,5 cinq fois
rep(1:5, each = 5) # répéter chaque élément du vecteur cinq fois

## Arithmétique vectorielle.
v <- 1:12               # initialisation d'un vecteur
v + 2                   # additionner 2 à chaque élément de v
v * -12:-1              # produit élément par élément
v + 1:3                 # le vecteur le plus court est recyclé

## Vecteur de nombres uniformes sur l'intervalle [1, 10].
v <- runif(12, min = 1, max = 10)
v

## Pour afficher le résultat d'une affectation, placer la
## commande entre parenthèses.
( v <- runif(12, min = 1, max = 10) )

## Arrondi des valeurs de v à l'entier près.
( v <- round(v) )

## Créer une matrice 3 x 4 à partir des valeurs de
## v. Remarquer que la matrice est remplie par colonne.
( m <- matrix(v, nrow = 3, ncol = 4) )

## Les opérateurs arithmétiques de base s'appliquent aux
## matrices comme aux vecteurs.
m + 2
m * 3
m ^ 2

## Éliminer la quatrième colonne afin d'obtenir une matrice
## carrée.
( m <- m[,-4] )

## Transposée et inverse de la matrice m.
t(m)
solve(m)

## Produit matriciel.
m %*% m                  # produit de m avec elle-même
m %*% solve(m)           # produit de m avec son inverse
round(m %*% solve(m))    # l'arrondi donne la matrice identité

## Consulter la rubrique d'aide de la fonction 'solve'.
?solve

## Liste des objets dans l'espace de travail.
ls()

## Nettoyage.
rm(x, y, v, m)
