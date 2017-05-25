### RStudio: -*- coding: utf-8 -*-
##
## Copyright (C) 2017 David Beauchemin, Samuel Cabral Cruz, Vincent Goulet
##
## This file is part of the project 
## "Introduction a R - Atelier du colloque R a Quebec 2017"
## http://github.com/vigou3/raquebec-atelier-introduction-r
##
## The creation is made available according to the license
## Attribution-Sharing in the same conditions 4.0
## of Creative Commons International
## http://creativecommons.org/licenses/by-sa/4.0/

#### Question 4 ####
# Import data of the competition
compData <- read.csv(paste(path,"/Reference/benchmark.csv",sep=""))
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

# Chi's Square Test of Independency between the two variables
weightsBinded <- as.numeric(cut(compData$weight,25))
distancesBinded <- as.numeric(cut(compData$distance,25))
contingencyTable <- table(weightsBinded,distancesBinded)
chisq.test(contingencyTable)
contingencyTable <- rbind(contingencyTable[1:4,],colSums(contingencyTable[5:18,]))
(contingencyTable <- cbind(contingencyTable[,1:14],rowSums(contingencyTable[,15:24])))
independencyTest <- chisq.test(contingencyTable)
head(independencyTest$expected)
head(independencyTest$observed)
head(independencyTest$stdres)
independencyTest
cor.test(compData$weight,compData$distance,method = "pearson")

# Linear model 
# we assume the same profit margin to simplify the situation
# We keep an intercept since we have a fixed cost
profitMargin <- 1.12
avgTaxRate <- sum(table(airportsCanada$province)*as.numeric(paste(taxRates$taxRate)))/length(airportsCanada$province)
compModel <- lm(price/(profitMargin*avgTaxRate) ~ distance + weight, compData)
summary(compModel)

# We plot the model
par(mfrow=c(2,2))
plot(compModel)

