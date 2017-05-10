### Emacs: -*- coding: utf-8; fill-column: 62; comment-column: 27; -*-
##
## Copyright (C) 2017 Vincent Goulet
##
## Ce fichier fait partie du projet «R à Québec - Atelier
## d'introduction à R»
## http://github.com/vigou3/raquebec-atelier-introduction-r
##
## Cette création est mise à disposition selon le contrat
## Attribution-Partage dans les mêmes conditions 4.0
## International de Creative Commons.
## http://creativecommons.org/licenses/by-sa/4.0/

###
### DONNÉES ET OPÉRATEURS DE BASE
###

## Nombres. Tous les nombres réels sont stockés en double
## précision dans R, entiers comme nombres fractionnaires.
486                        # nombre réel entier
0.3324                     # nombre réel fractionnaire
2e-3                       # notation scientifique
1 + 2i                     # nombre complexe

## Tout objet en R comporte au minimum un mode et une
## longueur.
mode(486)                  # pas de distinction entre entier...
mode(0.3324)               # nombre réel
length(486)                # vecteur de longueur 1
mode(1 + 2i)               # nombre complexe

## Valeurs booléennes. 'TRUE' et 'FALSE' sont des noms
## réservés pour identifier les valeurs booléennes
## correspondantes.
TRUE                       # vrai
FALSE                      # faux
mode(TRUE)                 # mode "logical"
! FALSE                    # négation logique
TRUE & FALSE               # ET logique
TRUE | FALSE               # OU logique

## Donnée manquante. 'NA' est un nom réservé pour représenter
## une donnée manquante.
c(65, NA, 72, 88)          # traité comme une valeur
NA + 2                     # tout calcul avec 'NA' donne NA
is.na(c(65, NA))           # tester si les données sont 'NA'

## Valeurs infinies et indéterminée. 'Inf', '-Inf' et 'NaN'
## sont des noms réservés.
1/0                        # +infini
-1/0                       # -infini
0/0                        # indétermination
x <- c(65, Inf, NaN, 88)   # s'utilisent comme des valeurs
is.finite(x)               # quels sont les nombres réels?
is.nan(x)                  # lesquels sont indéterminés?

## Valeur "néant". 'NULL' est un nom réservé pour représenter
## le "néant", "rien".
mode(NULL)                 # le mode de 'NULL' est NULL
length(NULL)               # longueur nulle
c(NULL, NULL)              # du néant ne résulte que le néant

## Chaines de caractères. On crée une chaine de caractère en
## l'entourant de guillemets doubles " ".
"foobar"                   # *une* chaine de 6 caractères
length("foobar")           # longueur de 1
c("foo", "bar")            # *deux* chaines de 3 caractères
length(c("foo", "bar"))    # longueur de 2

## On crée des nouveaux objets en leur affectant une valeur
## avec l'opérateur '<-'. *Ne pas* utiliser '=' pour
## l'affectation.
x <- 5                     # affecter 5 à l'objet 'x'
x                          # voir le contenu
(x <- 5)                   # affecter et afficher
y <- x                     # affecter la valeur de 'x' à 'y'
x <- y <- 5                # idem, en une seule expression
y                          # 5
x <- 0                     # changer la valeur de 'x'...
y                          # ... ne change pas celle de 'y'

###
### VECTEURS
###

## La fonction de base pour créer des vecteurs est 'c'. Il
## peut s'avérer utile de nommer les éléments d'un vecteur.
x <- c(a = -1, b = 2, c = 8, d = 10) # création d'un vecteur
names(x)                             # extraire les noms
names(x) <- letters[1:length(x)]     # changer les noms
x[1]                       # extraction par position
x["c"]                     # extraction par étiquette
x[-2]                      # élimination d'un élément

## Les fonctions 'numeric', 'logical', 'complex' et
## 'character' servent à créer des vecteurs initialisés avec
## des valeurs par défaut.
numeric(5)                 # vecteur initialisé avec des 0
logical(5)                 # initialisé avec FALSE
complex(5)                 # initialisé avec 0 + 0i
character(5)               # initialisé avec chaines vides

## L'unité de base de l'arithmétique en R est le vecteur. Cela
## rend très simple et intuitif de faire des opérations
## mathématiques courantes. Là où plusieurs langages de
## programmation exigent des boucles, R fait le calcul
## directement. En effet, les règles de l'arithmétique en R
## sont globalement les mêmes qu'en algèbre vectorielle et
## matricielle.
5 * c(2, 3, 8, 10)         # multiplication par une constante
c(2, 6, 8) + c(1, 4, 9)    # addition de deux vecteurs
c(0, 3, -1, 4)^2           # élévation à une puissance

## Dans les règles de l'arithmétique vectorielle, les
## longueurs des vecteurs doivent toujours concorder. R permet
## plus de flexibilité en recyclant les vecteurs les plus
## courts dans une opération. Il n'y a donc à peu près jamais
## d'erreurs de longueur en R! C'est une arme à deux
## tranchants: le recyclage des vecteurs facilite le codage,
## mais peut aussi résulter en des réponses complètement
## erronées sans que le système ne détecte d'erreur.
8 + 1:10                   # 8 est recyclé 10 fois
c(2, 5) * 1:10             # c(2, 5) est recyclé 5 fois
c(-2, 3, -1, 4)^(1:4)      # quatre puissances différentes

###
### FONCTIONS
###

## une fonction est un objet normal
seq                        # le voir
c(seq, rep)                # vecteur de fonctions
x <- c(seq, rep)                # vecteur de fonctions

## exemple de syntaxe

## règles d'appel d'une fonction

## syntaxe de base pour créer une fonction

## lexical scope

## fonction anonyme

## argument '...'
