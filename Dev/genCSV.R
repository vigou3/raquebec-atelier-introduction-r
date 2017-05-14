
#
# Génération du fichier benchmark.csv
#

#
# To used the code you need to run the CaseStudyDEv up to the end of question 2
#

#
# parameters of the simulation
#
n <- 100000
x <- matrix(runif(4*n),ncol = 4,byrow = TRUE)

# Générer des poids selon logNormale
mu1 <- log(3000)
sigma1 <- log(1.8)
exp(mu1+sigma1**2/2)
exp(2*mu1+4*sigma1**2/2)-exp(mu1+sigma1**2/2)**2
weights <- round(qlnorm(x[,1],mu1,sigma1)/1000,3)
mean(weights)
hist(weights,breaks = 100,freq=FALSE)
max(weights)

# Générer des erreurs sur le poids
weightsTarifParam <- 0.7
weightsPrice <- weightsTarifParam*weights
weightsError <- pnorm((x[,3]-0.5)*sqrt(12))*sd(weights)*weightsTarifParam
weightsFinalPrice <- weightsPrice + weightsError
mean(weightsFinalPrice)
var(weightsFinalPrice)

# Générer des distances selon logNormale
routesCanada
routesIATA <- cbind(paste(routesCanada$sourceAirport),paste(routesCanada$destinationAirport))
routesDistance <- apply(routesIATA, 1, function(x) airportsDist(x[1],x[2])$value)
max(routesDistance)
mean(routesDistance)
mu2 <- log(650)
sigma2 <- log(1.4)
(distances <- round(qlnorm(x[,2],mu2,sigma2)))
mean(distances)
hist(distances,breaks = 100,freq=FALSE)
max(distances)

# Générer des erreurs sur la distance
distancesTarifParam <- 0.0275
distancesPrice <- distancesTarifParam*distances #pondéré par aéroport
distancesError <- pnorm((x[,3]-0.5)*sqrt(12))*sd(distances)*distancesTarifParam
distancesFinalPrice <- distancesPrice + distancesError
mean(distancesFinalPrice)
var(distancesFinalPrice)

# Générer prix totaux
baseCost <- 5
taxRate <- mean(as.numeric(as.character(taxRates$taxRate)))
profitMargin <- 1.15
(totalCost <- round((baseCost + weightsFinalPrice + distancesFinalPrice)*profitMargin*taxRate,2))
mean(totalCost)
var(totalCost)
max(totalCost)
min(totalCost)


# Exporter le data en csv
(dataExport <- cbind(weights,distances,totalCost))
colnames(dataExport) <- c("Poids","Distance","Prix")
write.csv(dataExport,paste(path,"/Reference/benchmark.csv",sep=''),row.names = FALSE)
