#R à Québec 2017 - Atelier d’introduction à R
#Deuxième Partie - Étude de cas
##Horaire
Jeudi le 25 mai - 13h à 16h

##Description Sommaire
Dans le cadre de cette étude de cas, nous nous placerons dans la peau d'un analyste du département de tarification oeuvrant au sein d'une compagnie se spécilisant dans le transport de colis par voies aériennes en mettant à profit le jeu de données d'[OpenFlights](https://openflights.org/data.html).

##Mandat
Notre mandat consistera dans un premier temps à analyser les bases de données que nous avons à notre disposition afin de créer des fonctions qui permettront de facilement intégrer les informations qu'elles contiennent lors de la tarification d'une livraison spécifique. Une fois cette tarification complétée, nous devrons fournir des chartes pour facilement approximer les prix d'une livraison qui s'avèrront être des outils indispensable au département de marketing et au reste de la direction. Après avoir transmis les documents en question, votre gestionnaire voulant s'assurer que la nouvelle tarification sera efficiente et profitable vous demandera d'analyser les prix de la concurrence pour en extraire 

##Question 1
Librairy
Extraire les donnÃ©es directement du site
Travail sur les donnÃ©es
visualisation du data
     Faire une carte
          afficher toutes les aÃ©roports
          le flow de trajet en provenance et en arrivÃ© en diagramme Ã  bande et en carte

##Question 2
a)
Les fonctions offre un frame avec les paramÃ¨tres obligatoires
Fonction calcul de distance 
Sous fonction des times zones
Fonction calcul de temps avec fuseau horaire (vitesse 500 km)
     Time computer (upper floor) + time zone  et date constante
     
Fonction de coÃ»ts (prix d'envoie pour un client) {dÃ©part, arriver, ...}
     calcul du cost en fonction du poids (avec une loi - poisson/gamma paramÃ©trique), distance et frÃ©quence des vols de l'aÃ©roports et arriver (fonction de survie appliquer sur le prix (frÃ©quence) avec CDF)
     Frais fixe (administration et infrastructure) - constante canadien
     Marge de profit en paramÃ¨tre (paramÃ¨tre par dÃ©faut) - % constant
     Rabais applicable - % avec valeur de dÃ©faut
     Taxes sÃ©rie de case ou if avec Internet
     = prix du transport pour le client
     * vÃ©rification des paramÃ¨tres avec message d'erreur (print)
          Prix pas nÃ©gatif
          Distance minimale - constante 

b)
Le departement de marketing de MontrÃ©al ait de la facilitÃ© d'estimer les coÃ»ts en fonction du poids et de la distance. Toronto, Calgary et Vancouver (plusieurs graphiques dans mÃªme fenÃªtre)

plot - Repartition de la fonction de coÃ»ts (poids varie, le reste non)
plot - Repartition de la fonction de coÃ»ts (distance varie, le reste non)



#Question 3 simulation : PrÃ©diction sur les profits annuels
a)
Pour nous: Poids distance compÃ©titeur
Data Excel
Poids alÃ©atoire log normal asymÃ©trique vers la gauche
distance alÃ©atoire lognormal 
gÃ©nÃ¨re un data 
Ajustement data:
     on applique un fonction de coÃ»ts linÃ©aire (vrai prix)
     Rajoute du bruit (fausser le prix) dans les petits colis et dans les distances moyennes
          En fonction du kappa ->impact du bruit 

lm avec les datas fournis en deux dimensions (coÃ»ts et distance)

b)De montrÃ©al
On utilise optim pour refiter Ã  partir du data la loi de distribution - Normale, gamma, Lognormal, weibull

Avec la loi de distribution trouver avec optim, on fait de la simulation
     la distribution des clients suit une poisson de paramÃ¨tre lambda mensuel = variable (rpoisson) (constante)
     
     Distribution trouvÃ©e -> simulation annuelle des poids par clients
     simulation des arriver -> 1/417 runif

     
Chaque client prends la cie la moins cher
sur le data on applique notre fonction de coÃ»ts et celle du compÃ©titeur on calcul les deux prix.
qui est les moins cher entre les deux (0 et 1)


Calcul les revenus/part de marchÃ© des deux compagnies
plot et curve


SupplÃ©mentaire:
Travail sur les graphiques

##Auteurs:
* David Beauchemin
* Samuel Cabral Cruz

##Liens utiles:
* [Colloque R](http://raquebec.ulaval.ca/2017/)

![alt text](https://www.google.ca/url?sa=i&rct=j&q=&esrc=s&source=images&cd=&ved=0ahUKEwiilODnvNzTAhWC64MKHYBuA_QQjBwIBA&url=http%3A%2F%2Fwww.iconarchive.com%2Fdownload%2Fi89699%2Falecive%2Fflatwoken%2FApps-Haroopad.ico&psig=AFQjCNFThnM3DM-g64vq4jmpEV4U6cxzHw&ust=1494201584011198)