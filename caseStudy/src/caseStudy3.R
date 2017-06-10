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


#### Question 3 ####
# We create a visual support ploting the relationship between the weight 
# and the price
# Source airport : YUL
# Destination airport : YQB, YVR, YYZ and YYC
curve(shippingCost("YUL","YQB",x)$price,0.01,50,ylim = c(0,200),
      main = "Shipping Price Variation according to the Weight",
      xlab = "weight (Kg)",
      ylab = "price (CND $)",
      lwd = 2)
curve(shippingCost("YUL","YVR",x)$price,0.01,50,
      xlab = "weight (Kg)",
      ylab = "price (CND $)",
      add = TRUE, 
      col = "red", 
      lwd = 2)
curve(shippingCost("YUL","YYZ",x)$price,0.01,50,
      xlab = "weight (Kg)",
      ylab = "price (CND $)",
      add = TRUE, 
      col = "blue", 
      lwd = 2)
curve(shippingCost("YUL","YYC",x)$price,0.01,50,
      xlab = "weight (Kg)",
      ylab = "price (CND $)",
      add = TRUE, 
      col = "purple", 
      lwd = 2)
text(x = c(25,25,25,25),
     y = c(50,90,140,175),
     c("YUL-YYZ","YUL-YQB","YUL-YVR","YUL-YYC"),
     adj = 0.5,
     cex = 0.75,
     font = 2,
     col = c("blue","black","red","purple"))