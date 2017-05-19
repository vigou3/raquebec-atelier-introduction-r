# Code source Case Study R à Québec 2017

#### Setting working directory properly ####
getwd()
setwd('..')
(path <- getwd())
set.seed(31459)

#### Question 1 - Extraction, traitement, visualisation et analyse des données ####

# 1.1 - Extraction des bases de données Airports.dat, routes.dat et airlines.dat
airports <- read.csv("", na.strings=c('\\N',''))
routes <- read.csv("",  na.strings=c('\\N',''))
airlines <- read.csv(" ", na.strings=c('\\N',''))

# 1.2 - On garde l'informations pour la Canada seulement
airportsCanada <- airports[airports$country=='Canada',]

# 1.3 - Extraire des informations générales sur la distribution des variables présentent dans le jeu de données 
# et vous informer sur la signification de ces dernières ainsi que sur les différentes modalités quelles peuvent 
# prendre

#Voici différente fonction R qui vous permette de visualiser les données
View(airportsCanada)
head(airportsCanada)
summary(airportsCanada)

nbAirportCity <- table(airportsCanada$city) 
(nbAirportCity <- sort(nbAirportCity,decreasing=TRUE))[1:10]

# Filtrer la pertinence des données
# 1.5 - Corriger les modalités des variables et faire une sélection des variables qui vous semble utiles 
# pour le reste du traitement
# Nous observons que les variables typeAirport et Source ne sont d'aucune utilité dans la situation présente
# compte tenu que nous n'utilisons que l'information sur le transport par voies aériennes.
# Un raisonnement similaire est applicable pour la variable country qui ne possèdera que la modalité Canada
airportsCanada <- subset(airportsCanada, select = -c(country, timezone, DST, tzFormat, typeAirport, Source ))


# Comme on l'a vu dans le sumary(), nous n'avons pas l'IATA pour 27 aéroports
airportsCanada[is.na(airportsCanada$IATA),c("airportID","name","IATA","ICAO")]

# Cependant, toutes ces aéroports possèdent un code ICAO bien défini ce qui permettra d'attribuer une valeur
# par défaut. Une autre possibilité aurait été de simplement ignorer ces aéroports dans le reste de l'analyse.
# Cette approximation ne semble pas trop contraignante compte tenu du fait que les trois derniers caractères
# du code ICAO correspondent au code IATA dans 82% des cas.
sum(airportsCanada$IATA==substr(airportsCanada$ICAO,2,4),na.rm = TRUE)/sum(!is.na(airportsCanada$IATA))

# Nous sommes maintenant en mesure de combler les IATA manquante et nous supprimons l'ICAO car il est maintenant inutile
airportsCanada$IATA <- as.character(airportsCanada$IATA) 
airportsCanada$IATA[is.na(airportsCanada$IATA)] <- substr(airportsCanada$ICAO[is.na(airportsCanada$IATA)],2,4) 
airportsCanada$IATA <- as.factor(airportsCanada$IATA)
airportsCanada <- subset(airportsCanada, select = -ICAO)
View(airportsCanada)


################ Merge le data des provinces avec les aéroports


#tapply

routesCanada <- sqldf("
                      select *
                      from routes
                      where sourceAirportID in (select distinct airportID
                      from airportsCanada)
                      and destinationAirportID in (select distinct airportID
                      from airportsCanada)")
routesCanada  <- data.frame(as.matrix(routesCanada ))

# Produira le même résultat
# x <- routesCanada[!is.na(match(routesCanada$sourceAirportID,airportsCanada$airportID)) &
#              !is.na(match(routesCanada$destinationAirportID,airportsCanada$airportID)),]
# routesCanada <- routesCanada[!is.na(match(routesCanada$sourceAirport,airportsCanada$IATA)) &
#                 !is.na(match(routesCanada$destinationAirport,airportsCanada$IATA)),]

summary(routesCanada)
unique(routesCanada$airline)
unique(routesCanada[,c("airline","airlineID")])
unique(routesCanada$airlineID)
summary(airlines)
#tapply or by or select
(airlinesCanada <- sqldf("
                         select *
                         from airlines
                         where IATA in (select distinct airline
                         from routesCanada)"))
routesCanada[is.na(routesCanada$airlineID),]
unique(routesCanada$airlineID)
unique(routesCanada[is.na(routesCanada$airlineID),]$airline)
summary(routesCanada$stops)
# Comme nous pouvons le remarquer, il n'y a que deux vols qui ne sont pas directs,
# Pour des fins de simplification, nous allons considérer tous les vols comme étant 
# des vols directs
# De plus, la notion de codeshare ne sera pas utile compte tenu que la livraison de
# de marchandise peut autant se faire par l'intermédiaire d'agence aérienne que par 
# vol privé.
# Nous pouvons ainsi nous débarasser de ces variables
routesCanada <- subset(routesCanada, select = -c(codeshare, stops))
summary(routesCanada)

# 1.6 - Créer une carte affichant les différents aéroports sur une carte du Canada
# install.packages("ggmap")
library(ggmap)
map <- get_map(location = 'Canada', zoom = 3)
lon <- as.numeric(paste(airportsCanada$longitude))
lat <- as.numeric(paste(airportsCanada$latitude))
airportsCoord <- as.data.frame(cbind(lon, lat))
(mapPoints <- ggmap(map) + geom_point(data=airportsCoord,aes(lon,lat),alpha=0.5))

# 1.7 - Créer une seconde carte montrant toutes les routes possibles entre ces différents aéroports
summary(routesCanada)
summary(airportsCanada)

#tapply ou selct ou by
routesCoord <- sqldf("
                     select 
                     a.sourceAirport, 
                     a.destinationAirport,
                     b.longitude as sourceLon,
                     b.latitude as sourceLat,
                     c.longitude as destLon,
                     c.latitude as destLat
                     from routesCanada a
                     left join airportsCanada b
                     on a.sourceAirport = b.IATA
                     left join airportsCanada c
                     on a.destinationAirport = c.IATA")
lonBeg <- as.numeric(paste(routesCoord$sourceLon))
latBeg <- as.numeric(paste(routesCoord$sourceLat))
lonEnd <- as.numeric(paste(routesCoord$destLon))
latEnd <- as.numeric(paste(routesCoord$destLat))
routesCoord <- as.data.frame(cbind(lonBeg,latBeg,lonEnd,latEnd))
(mapRoutes <- mapPoints + geom_segment(data=routesCoord,aes(x=lonBeg,y=latBeg,xend=lonEnd,yend=latEnd),alpha=0.5))

# Calculer un indice d'achalandage des aéroports en fonction de la quantitée de routes en destination
arrivalFlights <- table(routesCanada$destinationAirport)
departureFlights <- table(routesCanada$sourceAirport)
totalFlights <- arrivalFlights + departureFlights
max(totalFlights)
mean(totalFlights)
var(totalFlights)
sd(totalFlights)
head(sort(totalFlights,decreasing = TRUE),n = 30)
totalFlightsCDF <- ecdf(totalFlights)
IATA <- names(totalFlights)

# Tracer l'index
curve(totalFlightsCDF(x-1),from = 0,to = 60,n = 100,
      xlab = "Nombre de routes par aéroport", 
      ylab = "CDF")

# Calculer un indice combiné des deux derniers indices
combinedIndex <- round(totalFlights/max(totalFlights),3)
combinedIndexTable <- data.frame(IATA,
                                 as.numeric(paste(totalFlights)),
                                 as.numeric(paste(combinedIndex)))
rownames(combinedIndexTable) <- NULL
colnames(combinedIndexTable) <- c("IATA","totalFlights","combinedIndex")
combinedIndexTable

#tapply, select ou by
airportsCanada <- sqldf("
                        select 
                        a.*,
                        coalesce(b.combinedIndex,0) as combinedIndex
                        from airportsCanada a
                        left join combinedIndexTable b
                        on a.IATA = b.IATA")
airportsCanada <- data.frame(as.matrix(airportsCanada ))

#1.11 - Créer des cartes permettant de visualiser ces indices grâce à un graphique à bulles
lon <- as.numeric(paste(airportsCanada$longitude))
lat <- as.numeric(paste(airportsCanada$latitude))
size <- as.numeric(paste(airportsCanada$combinedIndex))
airportsCoord <- as.data.frame(cbind(lon, lat, size))
mapPoints <- 
     ggmap(map) + 
     geom_point(data=airportsCoord,aes(x=lon,y=lat,size=size),alpha=0.5,shape=16)
(mapTraffic <-  
          mapPoints + 
          scale_size_continuous(range = c(0, 20),name = "Traffic Index"))

#### Question 2 #####

# Fonction de calcul de distance entre deux aéroports
# install.packages("geosphere")
library(geosphere)
airportsDist <- function(sourceIATA,destIATA)
{
     # vérifions que sourceIATA et destIATA sont des IATA valides
     sourceFindIndex <- match(sourceIATA,airportsCanada$IATA)
     if(is.na(sourceFindIndex))
     {
          stop(paste('sourceIATA :',sourceIATA,'is not a valid IATA code'))
     }
     destFindIndex <- match(destIATA,airportsCanada$IATA)
     if(is.na(destFindIndex))
     {
          stop(paste('destIATA :',destIATA,'is not a valid IATA code'))
     }
     sourceLon <- as.numeric(paste(airportsCanada$longitude))[sourceFindIndex]
     sourceLat <- as.numeric(paste(airportsCanada$latitude))[sourceFindIndex]
     sourceCoord <- c(sourceLon,sourceLat)
     destLon <- as.numeric(paste(airportsCanada$longitude))[destFindIndex]
     destLat <- as.numeric(paste(airportsCanada$latitude))[destFindIndex]
     destCoord <- c(destLon,destLat)
     airportDistList <- list()
     airportDistList$source <- sourceIATA
     airportDistList$dest <- destIATA
     airportDistList$value <- round(distGeo(sourceCoord,destCoord)/1000)
     airportDistList$metric <- "Km"
     airportDistList$xy_dist <- sqrt((sourceLon - destLon)**2 + (sourceLat - destLat)**2)
     airportDistList$sourceIndex <- sourceFindIndex
     airportDistList$destIndex <- destFindIndex
     airportDistList
}
airportsDist('AAA','YQB')
airportsDist('YUL','AAA')
airportsDist('YPA','YQB')
airportsDist('YUL','YQB')
airportsDist('YUL','YQB')$value


# Importer les taux de taxation par province directement du web
# install.packages("XML")
# install.packages("RCurl")
# install.packages("rlist")
library(XML)
library(RCurl)
library(rlist)
theurl <- getURL("http://www.calculconversion.com/sales-tax-calculator-hst-gst.html",.opts = list(ssl.verifypeer = FALSE))
tables <- readHTMLTable(theurl)
provinceName <- as.character(sort(unique(airportsCanada$province)))
taxRates <- as.data.frame(cbind(provinceName,as.numeric(sub("%","",tables$`NULL`[-13,5]))/100+1))
colnames(taxRates) <- c("province","taxRate")
taxRates
######## vérifier si retrait ou non. étant donner que province dans le dataset déjà modifier fonction

# Fonction de calcul des coûts
shippingCost <- function(sourceIATA, destIATA, weight, 
                         percentCredit = 0, dollarCredit = 0)
{
     # vérifions qu'il existe une route entre sourceIATA et destIATA 
     routeConcat <- as.character(paste(routesCanada$sourceAirport,routesCanada$destinationAirport))
     if(is.na(match(paste(sourceIATA,destIATA),routeConcat)))
     {
          stop(paste('the combination of sourceIATA and destIATA (',sourceIATA,'-',destIATA,') do not corresponds to existing route'))
     }
     
     if(weight < 0 || weight > 30) 
     {
          stop("The weight must be between 0 and 30 Kg")
     }
     
     if(percentCredit < 0 || percentCredit > 1)
     {
          stop("The percentage of credit must be between 0 % and 100 %")
     }
     
     if(dollarCredit < 0)
     {
          stop("The dollar credit must be superior to 0 $")
     }
     
     minimalDist = 100
     distance <- airportsDist(sourceIATA, destIATA)
     if (distance$value < minimalDist)
     {
          # Nous vérifions si la distance de livraison est supérieure à l'exigence minimale
          stop(paste("The shipping distance is under the minimal requirement of",minDist,"Km"))
     }
     
     # Variables de tarification
     distanceFactor <- 0.03
     weightFactor <- 0.8
     fixedCost <- 3.75
     profitMargin <- 1.12
     
     # Indice de trafic de l'aéroport
     traficIndexSource <- as.numeric(paste(airportsCanada[distance$sourceIndex,"combinedIndex"]))
     traficIndexDest <- as.numeric(paste(airportsCanada[distance$destIndex,"combinedIndex"]))
     
     # Calcul du coût de base
     baseCost <-  fixedCost + (distance$value*distanceFactor + weight*weightFactor)/(traficIndexSource*traficIndexDest)
     
     # Crédits automatisés supplémentaires
     automatedCredit <- 1
     # Lightweight
     automatedCredit <-  automatedCredit * ifelse(weight < 2, 0.5, 1)
     # Gold Member
     automatedCredit <-  automatedCredit * ifelse(baseCost > 100, 0.9, 1)
     # Partnership
     automatedCredit <- automatedCredit * switch(sourceIATA,
                                                 "YUL" = 0.85,
                                                 "YHU" = 0.95,
                                                 "YMX" = 0.95,
                                                 "YYZ" = 0.9,
                                                 "YKZ" = 0.975,
                                                 "YTZ" = 0.975,
                                                 "YZD" = 0.975)
     # The Migrator
     if(distance$value > 3500)
     {
          automatedCredit <- automatedCredit * 0.8125
     }
     else if(distance$value >= 3000)
     {
          automatedCredit <- automatedCredit * 0.825
     }
     else if(distance$value >= 2500)
     {
          automatedCredit <- automatedCredit * 0.85
     }
     else if(distance$value >= 2000)
     {
          automatedCredit <- automatedCredit * 0.9
     }
     
     # Calcul du taux de taxes et du contrôle de texte
     taxRate <- as.numeric(paste(taxRates[match(airportsCanada[distance$sourceIndex,"province"],taxRates$province),"taxRate"]))
     price <- round(pmax(fixedCost*profitMargin*automatedCredit*taxRate,(baseCost*automatedCredit*profitMargin - dollarCredit)*(1 - percentCredit)*taxRate),2)
     
     # Liste retourné par la fonction
     shippingCostList <- list()
     shippingCostList$distance <- distance
     shippingCostList$weight <- weight
     shippingCostList$distanceFactor <- distanceFactor
     shippingCostList$weightFactor <- weightFactor
     shippingCostList$fixedCost <- fixedCost
     shippingCostList$profitMargin <- profitMargin
     shippingCostList$percentCredit <- percentCredit
     shippingCostList$dollarCredit <- dollarCredit
     shippingCostList$minimalDist <- minimalDist
     shippingCostList$traficIndex <- list(traficIndexSource,traficIndexDest)
     shippingCostList$baseCost <- baseCost
     shippingCostList$automatedCredit <- 1-automatedCredit
     shippingCostList$taxRate <- taxRate
     shippingCostList$price <- price
     shippingCostList
}
shippingCost("YUL", "YVR", 1)
shippingCost("YUL", "YQB", 1)
shippingCost("YUL", "YVR", 30)
shippingCost("YUL", "YQB", 30)

#### Question 3 ####
curve(shippingCost("YUL","YQB",x)$price,0.01,50,ylim=c(0,200),
      main="Shipping Price Variation with Weight",xlab="weight (Kg)",
      ylab="price (CND $)",lwd = 2)
curve(shippingCost("YUL","YVR",x)$price,0.01,50,xlab="weight (Kg)",
      ylab="price (CND $)",add=TRUE, col = "red", lwd = 2)
curve(shippingCost("YUL","YYZ",x)$price,0.01,50,xlab="weight (Kg)",
      ylab="price (CND $)",add=TRUE, col = "blue", lwd = 2)
curve(shippingCost("YUL","YYC",x)$price,0.01,50,xlab="weight (Kg)",
      ylab="price (CND $)",add=TRUE, col = "purple", lwd = 2)
text(x=c(45,45,45,45),y=c(50,110,140,175),c("YUL-YYZ","YUL-YQB","YUL-YVR","YUL-YYC"),adj = 0.5,cex = 0.75,font = 2,col = c("blue","black","red","purple"))



#### Question 4 ####
# Import data
compData <- read.csv(paste(path,"/Reference/benchmark.csv",sep=''))
View(compData)
colnames(compData) <- c("weight","distance","price")
summary(compData)

# Weight visualisation
hist(compData$weight, freq = TRUE, main = "Repartition according to the weight", 
     xlab = "weight (Kg)", col = "cadetblue",breaks = 50)
weightCDF <- ecdf(compData$weight)
curve(weightCDF(x),0,15,ylim = c(0,1),lwd = 2,
      xlab = "weight (Kg)",
      ylab = "Cumulative Distribution Function")

# Distance visualisation
hist(compData$distance, freq = TRUE, main = "Repartition according to the distance", 
     xlab = "distance (Km)", col = "cadetblue",breaks = 50)
distanceCDF <- ecdf(compData$distance)
curve(distanceCDF(x),0,2500,ylim = c(0,1),lwd = 2,
      xlab = "distance (Km)",
      ylab = "Cumulative Distribution Function")

# Price according to weight
plot(compData$weight,compData$price,main = "Price according to the weight",
     xlab = "weight (Kg)", ylab = "Price (CAD $)")

# Price according to distance
plot(compData$distance,compData$price,main = "Price according to the distance",
     xlab = "distance (Km)", ylab = "Price (CAD $)")

# Price according to weight and distance
# install.packages("rgl")
library(rgl)
plot3d(compData$weight,compData$distance,compData$price)

# Linear model
profitMargin <- 1.12
avgTaxRate <- sum(table(airportsCanada$province)*as.numeric(paste(taxRates$taxRate)))/length(airportsCanada$province)
compModel <- lm(price/(profitMargin*avgTaxRate) ~ distance + weight, compData)
summary(compModel)

# We plot the model
par(mfrow=c(2,2))
plot(compModel)


#### Question 5 ####
# install.packages("actuar")
library("actuar")


########### verifier on ne garde pas optim mais juste fitdistr et optim on leur fait un modèle simple genre 
###### trouver le poids qui minimise le coûts selon la distance

distName <- c("Normal","Gamma","LogNormal","Weibull","Pareto","InvGaussian")
empCDF <- ecdf(compData$weight)
empPDF <- function(x,delta=0.01)
{
     (empCDF(x)-empCDF(x-delta))/delta
}

distFit <- function(dist,...)
{
     dist = tolower(dist)
     args = list(...)
     if(dist == "normal")
     {
          law = "norm"
          nbparam = 2
     }
     else if(dist == "gamma")
     {
          law = "gamma"
          nbparam = 2
     }
     else if(dist == "lognormal")
     {
          law = "lnorm"
          nbparam = 2
     }
     else if(dist == "weibull")
     {
          law = "weibull"
          nbparam = 2
     }
     else if(dist == "pareto")
     {
          law = "pareto"
          nbparam = 2
     }
     else if(dist == "invgaussian")
     {
          law = "invgauss"
          nbparam = 2
     }
     else
     {
          message <- "The only distribution available are: 
          Nnormal, Gamma, LogNormal, Weibull, Pareto and InvGaussian.
          (The case is ignored)"
          stop(message)
     }
     if(nbparam != length(args))
     {
          message <- paste("There is a mismatch between the number of arguments passed to the function and the number of arguments needed to the distribution.",
                           "The",dist,"distribution is taking",nbparam,"parameters and",length(args),"parameters were given.")
          stop(message)
     }
     
     # Treament
     param <- optim(par = args, function(par) -sum(do.call(eval(parse(text = paste("d",law,sep=''))),c(list(compData$weight),par,log = TRUE))))
     devValue <- sum((empPDF(x <- seq(0,30,0.1))-do.call(eval(parse(text = paste("d",law,sep=''))),c(list(x),param$par)))**2)
     
     # Return List
     distFitList <- list() 
     distFitList$param <- param$par
     distFitList$errorValue <- param$value
     distFitList$devValue <- devValue
     distFitList
}


(resultDistFitting <- sapply(distName,function(x) unlist(distFit(x,1,1))))

law <- c("norm","gamma","lnorm","weibull","pareto","invgauss")
col <- c("red", "yellow", "purple", "green", "cyan", "blue")
x <- seq(0,30,0.1)

par(mfrow = c(1,2),font = 2)
plot(function(x) empCDF(x), xlim = c(0,15), main = "", xlab = "weight (Kg)", ylab = "CDF(x)")
invisible(sapply(1:length(law),function(i) curve(do.call(eval(parse(text = paste("p",law[i],sep = ''))),c(list(x), as.vector(resultDistFitting[c(1:2),i]))), add = TRUE, lwd = 3, col = col[i])))
hist(compData$weight, xlim = c(0,15), main = "", xlab = "weight (Kg)", breaks = 300,freq = FALSE)
invisible(sapply(1:length(law),function(i) curve(do.call(eval(parse(text = paste("d",law[i],sep = ''))),c(list(x), as.vector(resultDistFitting[c(1:2),i]))), add = TRUE, lwd = 3, col = col[i])))
legend(x="right",distName, inset = 0.1, col = col, pch = 20, pt.cex = 2, cex = 1, ncol = 1, bty = "n", text.width = 2, title = "Distribution")
mtext("Ajustement sur distribution empirique", side = 3, line = -2, outer = TRUE)

# On choisi donc la loi LogNormal qui possède la plus petite déviance et le meilleur ajustement
distChoice <- "LogNormal"
(paramAdjust <- resultDistFitting[c(1:2),match(distChoice,distName)])

#### On démontre avec fitdistr
library("MASS")
(fit.normal <- fitdistr(compData$weight,"normal"))
(fit.gamma <- fitdistr(compData$weight, "gamma"))
(fit.lognormal <- fitdistr(compData$weight, "lognormal"))
(fit.weibull <- fitdistr(compData$weight, "weibull"))


#### Question 6 ####
theurl <- getURL(paste("file:///",path,"/Statement/CaseStudyStatement.html",sep=''),.opts = list(ssl.verifypeer = FALSE))
tables <- readHTMLTable(theurl)
lambdaTable <- as.data.frame(tables$'NULL')
colnames(lambdaTable) <- c("Month","Avg3yrs")
lambdaTable

# On filtre les routes possibles à partir de 'YUL' et 
# on crée une distribution en fonction de l'indice de destination
simAirportsDests <- as.character(paste(routesCanada[routesCanada$sourceAirport == 'YUL',"destinationAirport"]))
simCombinedIndex <- combinedIndex[names(combinedIndex) %in% simAirportsDests]
airportsDensity <- simCombinedIndex/sum(simCombinedIndex)

# Fonction pour la simulation des prix de l'expédition de colis
simulShipmentPrice <- function(Arrival,Weight)
{
     ownPrice <- ifelse(is(testSim <- try(shippingCost('YUL',Arrival,Weight)$price,silent = TRUE),"try-error"),NA,testSim)
     distance <- airportsDist('YUL',Arrival)$value
     nd <- as.data.frame(cbind(distance,Weight))
     colnames(nd) <- c("distance","weight")
     compPrice <- predict(compModel,newdata = nd)
     customerChoice <- ifelse(is.na(ownPrice),0,ifelse(ownPrice < compPrice,1,0))
     rbind(Arrival,distance,Weight,ownPrice,compPrice,customerChoice)
}

# Fonction pour la simulation des paramètres d'expédition de colis
simulShipment <- function(simNbShipments)
{
     # On génère ensuite des poids pour chacun des colis
     simWeights <- eval(parse(text = paste("r",law[match(distChoice,distName)],sep = '')))(simNbShipments,paramAdjust[1],paramAdjust[2])
     # On génère finalement une destination pour chacun des colis (le départ se fera toujours à partir de 'YUL')
     simArrivals <- sample(size = simNbShipments,names(airportsDensity),prob = airportsDensity,replace = TRUE)
     sapply(seq(1,simNbShipments),function(x) simulShipmentPrice(simArrivals[x],simWeights[x]))
}

# Fonction pour la simulation globale
simulOverall <-function()
{
     # On génère n observations de la distribution Poisson avec param = sum(lambda)
     # La somme de distribution poisson indépendantes suit une distribution poisson avec param = sum(lambda)
     simNbShipments <- rpois(1 ,lambda = sum(as.numeric(paste(lambdaTable$Avg3yrs))))
     # On génère les simulations de chaque colis
     simulShipment(simNbShipments)
}

nsim <- 1
simulResults <- replicate(nsim, simulOverall(),simplify = FALSE)
(marketShareSales <- sapply(1:nsim,function(x) sum(as.numeric(simulResults[[x]][6,]))/length(simulResults[[x]][6,])))
(ownRevenus <- sum(as.numeric(simulResults[[1]][4,])*as.numeric(simulResults[[1]][6,]),na.rm = TRUE))
(compRevenus <- sum(as.numeric(simulResults[[1]][5,])*(1-as.numeric(simulResults[[1]][6,])),na.rm = TRUE))
(marketShareRevenus <- ownRevenus/(ownRevenus+compRevenus))

arrivalSales <- as.character(simulResults[[1]][1,simulResults[[1]][6,]==1]) 
distanceSales <- as.numeric(simulResults[[1]][2,simulResults[[1]][6,]==1])
weightSales <- as.numeric(simulResults[[1]][3,simulResults[[1]][6,]==1])

arrivalComp <- as.character(simulResults[[1]][1,simulResults[[1]][6,]==0]) 
distanceComp <- as.numeric(simulResults[[1]][2,simulResults[[1]][6,]==0])
weightComp <- as.numeric(simulResults[[1]][3,simulResults[[1]][6,]==0])

table(arrivalSales)
mean(distanceSales)
table(arrivalComp)
mean(distanceComp)
par(mfrow = c(1,1))
hist(weightSales,freq = FALSE,breaks = 100, xlim = c(0,15), main = "Sales vs Theoretical Weights Distribution", xlab = "weight (Kg)")
curve(do.call(eval(parse(text = paste("d",law[match(distChoice,distName)],sep = ''))),c(list(x),as.vector(paramAdjust))),add = TRUE, lwd = 2)
abline(v = v <- exp(paramAdjust[1]+paramAdjust[2]**2/2), lwd = 2)
text(v+0.75,0.3,as.character(round(v,2)))
abline(v = v <- mean(weightSales),col = "red", lwd = 2)
text(v - 0.75,0.3,round(v,2),col = "red")

