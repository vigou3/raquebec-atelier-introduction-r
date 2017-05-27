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

(path <- paste(getwd(),"../..",sep = "/"))

# Extraction of airports.dat 
airports <- read.csv("https://raw.githubusercontent.com/jpatokal/openflights/master/data/airports.dat",
                     header = FALSE, na.strings=c("\\N",""))
colnames(airports) <- c("airportID", "name", "city", "country", "IATA", "ICAO",
                        "latitude", "longitude", "altitude", "timezone", "DST",
                        "tzFormat","typeAirport","Source")

# Initial Proportion of missing tzFormat
length(airports$tzFormat[is.na(airports$tzFormat)])/length(airports$tzFormat)

# We use ShapeFile of TZ_world to fill the missing values
# install.packages("sp")		
# install.packages("rgdal")		
library(sp)		
library(rgdal)		
tz_world.shape <- readOGR(dsn=paste(path,"/ref/tz_world",sep=""),layer="tz_world")	
obs <- subset(airports,select = c("airportID","name","longitude","latitude"))
sppts <- SpatialPoints(subset(obs,select = c("longitude","latitude")))		
proj4string(sppts) <- CRS("+proj=longlat")		
sppts <- spTransform(sppts, proj4string(tz_world.shape))		
merged_tz <- cbind(obs,over(sppts,tz_world.shape))
sum(merged_tz$TZID == "uninhabited",na.rm = TRUE)
subset(merged_tz,TZID == "uninhabited")
is.na(merged_tz) <- merged_tz == "uninhabited"
sum(merged_tz$TZID == "uninhabited",na.rm = TRUE)

# install.packages("sqldf")		
library(sqldf)		
airports <- sqldf("select 		
                   a.*,
                   b.TZID as tzMerged,
                   coalesce(a.tzFormat,b.TZID) as tzCombined		
                   from airports a 		
                   left join merged_tz b		
                   on a.airportID = b.airportID		
                   order by a.airportID")		
airports <- as.data.frame(as.matrix(airports))
summary(airports)
names(airports)

# Verification with available time zones 
test <- subset(airports, !is.na(tzFormat))
sum(paste(test$tzFormat) == paste(test$tzMerged))/length(test$tzFormat)
errors <- subset(airports, paste(tzFormat) != paste(tzMerged) & !is.na(tzFormat) & !is.na(tzMerged))

# Export of the errors into a report
# install.packages("knitr")
library(knitr)
mdErrorsTable <- kable(subset(errors,select = c("airportID","name","IATA","tzFormat","tzMerged")),format = "markdown")
knit("errors",text = mdErrorsTable)

# install.packages("lubridate")
library(lubridate)
x <- Sys.time()
mean(totaldiff <- sapply(1:length(errors$tzFormat), function(i) difftime(force_tz(x,paste(errors$tzMerged)[i]),force_tz(x,paste(errors$tzFormat)[i]))))

couple <- unique(cbind(paste(errors$tzFormat),paste(errors$tzMerged)))
mean(couplediff <- sapply(1:nrow(couple), function(i) difftime(force_tz(x,couple[i,1]),force_tz(x,couple[i,2]))))

names(couplediff) <- paste(couple[,1],couple[,2])
y <- sort(couplediff, decreasing = TRUE)
y[abs(y) > 1]

(coupleWatching <-couple[order(couplediff,decreasing = TRUE),][abs(y) > 1,])
toValid <- subset(errors, paste(tzFormat,tzMerged) %in% paste(coupleWatching[,1],coupleWatching[,2]))
mdValidTable <- kable(row.names = FALSE,subset(toValid,select = c("airportID","name","IATA","tzFormat","tzMerged")),format = "markdown")
knit("valid",text = mdValidTable)

# install.packages("rmarkdown")
# library(rmarkdown)
# render(input = mdErrorsTable,output_file = "file",output_dir = ".")
# install.packages("markdown")
library(markdown)
markdownToHTML("errors.txt","errors.html",encoding = "utf8")
markdownToHTML("valid.txt","valid.html",encoding = "utf8")

airports <- subset(airports, select = -tzFormat)

# install.packages("plyr")
library(plyr)
summary(airports)
airports <- rename(airports, "tzMerged"="tzFormat")

# Final Proportion of missing tzFormat
length(airports$tzFormat[is.na(airports$tzFormat)])/length(airports$tzFormat)



