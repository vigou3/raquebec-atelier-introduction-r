# coding: utf-8
# CaseStudyRQuebec2017
# Authors : David Beauchemin & Samuel Cabral Cruz

#### Question 3 ####
# We visualize the impact of a changes of distance and the weight starting from the YUL airport.
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

