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
### EXÉCUTION CONDITIONNELLE
###

## Exemple où le résultat de la condition n'est pas une valeur
## TRUE ou FALSE unique.
x <- c(-2, 3, 5)
if (x > 0) x + 2 else x^2

## Utilisation typique d'une clause 'if' dans une fonction:
## vérifier la validité des arguments. Il vaut mieux faire ces
## tests au début de la fonction et en sortir avec 'stop' dès
## qu'un argument n'est pas valide. Remarquer l'absence de
## clause 'else'.
f <- function(x, y)
{
    if (any(x < 0))
        stop("'fun' valid for positive values of x only")

    mean(x[x > y])
}
f(x, 5)
f(c(5, 10, 20), 5)

###
### EXÉCUTION RÉPÉTÉE (BOUCLES ET CONTRÔLE DU FLUX)
###

### Méthode du point fixe

## Nous allons illustrer l'utilisation de boucles avec la
## méthode du point fixe. Il s'agit d'une méthode numérique
## simple et puissante de résolution d'une équation de la
## forme
##
##   x = f(x)
##
## qui consiste choisir un point de départ et à évaluer
## successivement f(x), f(f(x)), f(f(f(x))), ... jusqu'à ce
## que la valeur change «peu». L'algorithme est donc très
## simple:
##
## 1. Choisir une valeur de départ x[0].
## 2. Pour n = 1, 2, 3, ...
##    2.1 Calculer x[n] = f(x[n - 1])
##    2.2 Si |x[n] - x[n - 1]|/|x[n]| < TOL, passer à
##        l'étape 3.
## 3. Retourner la valeur x[n].

## Comme première illustration, supposons que nous avons
## besoin d'une fonction pour calculer la racine carrée d'un
## nombre, c'est à dire la valeur positive de y satisfaisant
## l'équation y^2 = x. Cette équation peut se réécrire sous
## forme de point fixe ainsi:
##
##   y = x/y.
##
## La méthode du point fixe ne converge avec cette fonction
## (l'algorithme oscille perpétuellement entre deux valeurs).
##
## Une variante de l'équation y^2 = x fonctionnera mieux (en
## fait, on peut démontrer que l'algorithme converge toujours
## pour cette fonction):
##
##   y = (y - x/y)/2.
##
## Voici une première mise en oeuvre de notre fonction 'sqrt'
## utilisant la méthode du point fixe.
sqrt <- function(x, start = 1, TOL = 1E-10)
{
    repeat
    {
        y <- (start + x/start)/2
        if (abs(y - start)/y < TOL)
            break
        start <- y
    }
    y
}
sqrt(9, 1)
sqrt(225, 1)
sqrt(3047, 50)

## Si nous voulions utiliser la méthode du point fixe pour
## résoudre une autre équation, il faudrait toutefois écrire
## une nouvelle fonction qui serait pour l'essentiel
## identique, sinon pour le calcul de la fonction
## (mathématique) f(x) pour laquelle nous cherchons le point
## fixe.
##
## Créons donc une fonction de point fixe générale qui prendra
## f(x) en argument.
fixed_point <- function(FUN, start, TOL = 1E-10)
{
    repeat
    {
        x <- FUN(start)
        if (abs(x - start)/x < TOL)
            break
        start <- x
    }
    x
}

## Nous pouvons ensuite écrire une nouvelle fonction 'sqrt'
## utilisant 'fixed_point'. Nous y ajoutons un test de
## validité de l'argument, pour faire bonne mesure.
sqrt <- function(x)
{
    if (x < 0)
        stop("cannot compute square root of negative value")

    fixed.point(function(y) (y + x/y)/2, start = 1)
}
sqrt(9)
sqrt(25)
sqrt(3047)

### Suite de Fibonacci

## La suite de Fibonacci est une suite de nombres entiers très
## connue. Les deux premiers termes de la suite sont 0 et
## 1 et tous les autres sont la somme des deux termes
## précédents:
##
##   f(0) = 0
##   f(1) = 1
##   f(n) = f(n - 1) + f(n - 2), n = 2, 3, ...
##
## Le quotient de deux termes successifs converge vers le
## nombre d'or (1 + sqrt(5))/2.

## Voici une première version d'une fonction calculant les 'n'
## premières valeurs de la suite de Fibonacci.
##
## Cette version est très inefficace. Pourquoi?
fib1 <- function(n)
{
    res <- c(0, 1)
    for (i in 3:n)
        res[i] <- res[i - 1] + res[i - 2]
    res
}
fib1(10)
fib1(20)





## [Espace délibérément laissé vide]





## La seconde version devrait s'avérer plus efficace parce que
## l'on initialise d'entrée de jeu un contenant de la bonne
## longueur que l'on remplit par la suite.
fib2 <- function(n)
{
    res <- numeric(n)      # contenant créé
    res[2] <- 1            # res[1] vaut déjà 0
    for (i in 3:n)
        res[i] <- res[i - 1] + res[i - 2]
    res
}
fib2(10)
fib2(20)

## A-t-on vraiment gagné en efficacité? Comparons le temps
## requis pour générer une longue suite de Fibonacci avec les
## deux fonctions.
system.time(fib1(100000))   # version inefficace
system.time(fib2(100000))   # version efficace
