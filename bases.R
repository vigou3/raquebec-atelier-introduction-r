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

## Les fonctions sont des objets comme les autres.
seq                        # contenu est le code source
mode(seq)                  # mode est "function"
rep(seq(5), 3)             # fonction argument d'une fonction
lapply(1:5, seq)           # idem
mode(ecdf(rpois(100, 1)))  # résultat est une fonction
ecdf(rpois(100, 1))(5)     # évaluation en un point
c(seq, rep)                # vecteur de fonctions!

### Règles d'appel d'une fonction

## L'interprète R reconnait un appel de fonction au fait que
## le nom de l'objet est suivi de parenthèses ( ).
##
## Une fonction peut n'avoir aucun argument ou plusieurs. Il
## n'y a pas de limite pratique au nombre d'arguments.
##
## Les arguments d'une fonction peuvent être spécifiés selon
## l'ordre établi dans la définition de la fonction.
##
## Cependant, il est beaucoup plus prudent et *fortement
## recommandé* de spécifier les arguments par leur nom avec
## une construction de la forme 'nom = valeur', surtout après
## les deux ou trois premiers arguments.
##
## L'ordre des arguments est important; il est donc nécessaire
## de les nommer s'ils ne sont pas appelés dans l'ordre.
##
## Certains arguments ont une valeur par défaut qui sera
## utilisée si l'argument n'est pas spécifié dans l'appel de
## la fonction.
##
## Examinons la définition de la fonction 'matrix', qui sert à
## créer une matrice à partir d'un vecteur de valeurs.
args(matrix)

## La fonction compte cinq arguments et chacun a une valeur
## par défaut (ce n'est pas toujours le cas). Quel sera le
## résultat de l'appel ci-dessous?
matrix()

## Les invocations de la fonction 'matrix' ci-dessous sont
## toutes équivalentes. On remarquera, entre autres, comment
## les arguments sont spécifiés (par nom ou par position).
matrix(1:12, 3, 4)
matrix(1:12, ncol = 4, nrow = 3)
matrix(nrow = 3, ncol = 4, data = 1:12)
matrix(nrow = 3, ncol = 4, byrow = FALSE, 1:12)
matrix(nrow = 3, ncol = 4, 1:12, FALSE)

### Définition de fonctions

## On définit une nouvelle fonction avec la syntaxe suivante:
##
##   <fun> <- function(<arguments>) <expression>
##
## où
##
## - 'fun' est le nom de la fonction;
## - 'arguments' est la liste des arguments, séparés par des
##    virgules;
## - 'expression' constitue le corps de la fonction, soit une
##   expression ou un groupe d'expressions réunies par des
##   accolades { }.
##
## Une fonction retourne toujours la valeur de la *dernière*
## expression de celle-ci.
##
## Voici un exemple trivial.
square <- function(x) x * x

## Appel de cette fonction.
square(10)

### Portée des variables

## La portée (domaine où un objet existe et comporte une
## valeur) des arguments d'une fonction et de tout objet
## défini à l'intérieur de celle-ci se limite à la fonction.
##
## Ceci signifie que l'interprète R fait bien la distinction
## entre un objet dans l'espace de travail et un objet utilisé
## dans une fonction (fort heureusement!).
x <- 5                     # objet dans l'espace de travail
square(10)                 # dans 'square' x vaut 10
x                          # valeur inchangée
square(x)                  # passer valeur de 'x' à 'square'
square(x = x)              # colle... signification?

## Le concept de portée va plus loin dans R.
##
## Tout appel de fonction crée un *environnement* dans lequel
## sont définis les objets.
##
## Un environnement hérite des objets définis dans
## l'environnement qui le contient.
##
## Par conséquent, si un objet n'existe pas dans un
## environnement, R va chercher dans les environnements parents
## pour en trouver la définition.
##
## En pratique, cela signifie qu'il n'est pas toujours
## nécessaire de passer des objets en argument. Il suffit de
## compter sur le concept de portée lexicale ("lexical scope").
##
## Supposons que l'on veut écrire une fonction pour calculer
##
##   f(x, y) = x (1 + xy)^2 + y (1 - y) + (1 + xy)(1 - y)
##
## Deux termes sont répétés dans cette expression. On a donc
##
##   a = 1 + xy
##   b = 1 - y
##
## et f(x, y) = x a^2 + y b + a b.
##
## Voici une manière élégante de procéder qui repose sur la
## portée lexicale.
f <- function(x, y)
{
    g <- function(a, b)
        x * a^2 + y * b + a * b
    g(1 + x * y, 1 - y)
}
f(2, 3)

### Fonctions anonymes

## Comme le nom du concept l'indique, une fonction anonyme est
## une fonction qui n'a pas de nom. C'est parfois utile pour
## des fonctions courtes utilisées dans une autre fonction.
##
## Reprenons l'exemple précédent en généralisant les
## expressions des termes 'a' et 'b'. La fonction 'f'
## pourrait maintenant prendre en arguments 'x', 'y' et des
## fonctions pour calculer 'a' et 'b'.
##
## On peut ensuite directement passer des fonctions anonymes
## en argument.
f <- function(x, y, fa, fb)
{
    g <- function(a, b)
        x * a^2 + y * b + a * b
    g(fa(x, y), fb(x, y))
}
f(2, 3,
  function(x, y) 1 + x * y,
  function(x, y) 1 - y)


## argument '...'
