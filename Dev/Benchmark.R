# Source code for the creation of the benchmark.csv file

# Parameters of the simulation
n <- 100000
x <- matrix(runif(4*n),ncol = 4,byrow = TRUE)

# Generate weights with a LogNormal distribution
mu1 <- log(3000)
sigma1 <- log(1.8)
exp(mu1+sigma1**2/2)
exp(2*mu1+4*sigma1**2/2)-exp(mu1+sigma1**2/2)**2
weights <- round(qlnorm(x[,1],mu1,sigma1)/1000,3)
hist(weights,breaks = 100,freq=FALSE)
mean(weights)
max(weights)

# Generate the errors on the weights
weightsTarifParam <- 0.7
weightsPrice <- weightsTarifParam*weights
weightsError <- pnorm((x[,3]-0.5)*sqrt(12))*sd(weights)*weightsTarifParam
weightsFinalPrice <- weightsPrice + weightsError
mean(weightsFinalPrice)
var(weightsFinalPrice)

# Generate the distance with a LogNormal distribution
# routesCanada
# routesIATA <- cbind(paste(routesCanada$sourceAirport),paste(routesCanada$destinationAirport))
# routesDistance <- apply(routesIATA, 1, function(x) airportsDist(x[1],x[2])$value)
# max(routesDistance)
# mean(routesDistance)
mu2 <- log(650)
sigma2 <- log(1.4)
(distances <- round(qlnorm(x[,2],mu2,sigma2)))
hist(distances,breaks = 100,freq=FALSE)
mean(distances)
max(distances)

# Generate the errors on the distances
distancesTarifParam <- 0.0275
distancesPrice <- distancesTarifParam*distances
distancesError <- pnorm((x[,3]-0.5)*sqrt(12))*sd(distances)*distancesTarifParam
distancesFinalPrice <- distancesPrice + distancesError
mean(distancesFinalPrice)
var(distancesFinalPrice)

# Generate total price
baseCost <- 5
#taxRate <- sum(table(airportsCanada$province)*as.numeric(paste(taxRates$taxRate)))/length(airportsCanada$province)
taxRate <- 1.082408
profitMargin <- 1.15
(totalCost <- round((baseCost + weightsFinalPrice + distancesFinalPrice)*profitMargin*taxRate,2))
mean(totalCost)
var(totalCost)
max(totalCost)
min(totalCost)

# Export to csv format
(dataExport <- cbind(weights,distances,totalCost))
colnames(dataExport) <- c("Poids (Kg)","Distance (Km)","Prix (CAD $)")
write.csv(dataExport,paste(path,"/Reference/benchmark.csv",sep=''),row.names = FALSE)
