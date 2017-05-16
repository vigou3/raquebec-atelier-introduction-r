#### Question 6 ####
theurl <- getURL(paste("file:///",path,"/Statement/CaseStudyStatement.html",sep=''),.opts = list(ssl.verifypeer = FALSE))
tables <- readHTMLTable(theurl)
lambdaTable <- as.data.frame(tables$'NULL', stringsAsFactors = TRUE)
colnames(lambdaTable) <- c("Month","Avg3yrs")
lambdaTable

# On filtre les routes possibles à partir de 'YUL' et 
# on crée une distribution en fonction de l'indice de destination
simAirportsDests <- as.character(paste(routesCanada[routesCanada$sourceAirport == 'YUL',"destinationAirport"]))
simCombinedIndex <- combinedIndex[names(combinedIndex) %in% simAirportsDests]
airportsDensity <- simCombinedIndex/sum(simCombinedIndex)

# Function for the simulation of the shipment prices
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

# Function for the simulation of the shipment parameters
simulShipment <- function(simNbShipments)
{
  # On génère ensuite des poids pour chacun des colis
  simWeights <- eval(parse(text = paste("r",law[match(distChoice,distName)],sep = '')))(simNbShipments,paramAdjust[1],paramAdjust[2])
  # On génère finalement une destination pour chacun des colis (le départ se fera toujours à partir de 'YUL')
  simArrivals <- sample(size = simNbShipments,names(airportsDensity),prob = airportsDensity,replace = TRUE)
  sapply(seq(1,simNbShipments),function(x) simulShipmentPrice(simArrivals[x],simWeights[x]))
}

# Function for overall simulation
simulOverall <-function()
{
  # On génère n observation de la distribution Poisson avec param = sum(lambda)
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

