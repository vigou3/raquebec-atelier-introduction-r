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
text(x=c(25,25,25,25),y=c(50,90,140,175),c("YUL-YYZ","YUL-YQB","YUL-YVR","YUL-YYC"),adj = 0.5,cex = 0.75,font = 2,col = c("blue","black","red","purple"))


fquad <- function(x,a=2,b=3,c=4)
{
  a*x**2+b*x+c
}
fquad(2)
par(mfrow = c(2,2))
plot(x <- seq(-10,10,10),fquad(x,2,3,4),type = "l",ylab = "fquad(x)",xlab = "x",main = "dx = 10")
plot(x <- seq(-10,10,5),fquad(x,2,3,4),type = "l",ylab = "fquad(x)",xlab = "x",main = "dx = 5")
plot(x <- seq(-10,10,2),fquad(x,2,3,4),type = "l",ylab = "fquad(x)",xlab = "x",main = "dx = 2")
plot(x <- seq(-10,10),fquad(x,2,3,4),type = "l",ylab = "fquad(x)",xlab = "x",main = "dx = 1")

par(mfrow = c(1,1))
curve(fquad(x),from = -10,to = 10)
