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

x <- c(-2, 3, 5)
if (x > 0) x + 2 else x^2


fun <- function(x, y)
{
    if (any(x < 0))
        stop("fonction valide seulement pour valeurs de x positives")

    mean(x[x > y])
}
fun(x, 5))
fun(c(5, 10, 20), 5)

###
### EXÉCUTION RÉPÉTÉE (BOUCLES)
###


## Newton-Raphson simplifié de xICP
