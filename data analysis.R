finaltable  
install.packages("psych")
library(psych)
p <-summary(finaltable)


transposed<-(summary(finaltable))
View(p)

describe(finaltable)
install.packages(ggplot2)
library(ggplot2)
install.packages("gridExtra")
library(gridExtra)
finaltable<-read.csv("C:\\Users\\hp\\OneDrive\\Desktop\\R PROJECT\\finaltable.csv")
df<-finaltable
plot_list<-list()
finaltable<-sapply(df, is.numeric)
par(mar=c(4,4,2,1))
for(colname in names(df)[finaltable]){
  p<-ggplot(df,aes_string(x=colname))+
    geom_histogram(bins=30,fill="skyblue", color="black")+
    ggtitle(colname)
  plot_list[[colname]]<-p
}
do.call("grid.arrange",c(plot_list,ncol=3))

for(colname in names(df)[finaltable]){
  p<-ggplot(df,aes_string(x=colname))+
    geom_boxplot(bins=30,fill="skyblue", color="black" )+
    ggtitle(colname)
  plot_list[[colname]]<-p
}
library(sqldf)
gd<-sqldf("select * from finaltable
          where grossprofit >0
          and profitmargin>0
          and totalsalesquantity>0")
gd
install.packages("corrplot")
library(corrplot)
library(dplyr)
finaltable<-sapply(gd, is.numeric)
cor_matrix <- cor(gd, use = "complete.obs")
corrplot(cor_matrix, method = "color", type = "upper",
         col=colorRampPalette(c("blue","white","red"))(200))



#BRANDS WITH LOW SALES BUT HIGH PROFIT MARGINS 

description<-sqldf("select sum(totalsalesdollars) as tsd , avg(profitmargin) as pm
, brand FROM gd
 group by brand")  
description
View(description)

low_sales_threshold<-quantile(description$tsd ,probs = 0.15, na.rm= TRUE)
low_sales_threshold

high_margin_threshold<-quantile(description$pm ,probs = 0.85, na.rm = TRUE)
high_margin_threshold

target_brand<-sqldf("select * from description
                    where tsd <= 563.53
                    and
                    pm >= 63.40
                    ORDER BY tsd")
target_brand
View(target_brand)
library(ggplot2)
ggplot() +
  geom_point(data=description, aes(x = tsd, y=pm),
             color="blue", alpha= 0.2)+
  geom_point(data=target_brand, aes(x = tsd, y=pm),
             color="red")+
  geom_hline(yintercept= high_margin_threshold, linetype= "dashed",
             color= "black", size= 0.5)+
  geom_vline(xintercept = low_sales_threshold, linetype= "dashed",
             color= "black", size= 0.5)+
  labs(
    x= "totalsales",
    y= "profitmargin",
    title="brands for promotional or pricing adjustments",
    color="brand type"
  )+
  theme_minimal()+
  theme(legend.position = "top")+
  scale_color_manual(values= c("All Brands"= "blue", "target brand"= "red"))
                    
# brands and vendor demonstrate the highest sales performance

top_vendor<- sqldf("select vendorNumber, sum(totalsalesdollars) as tsd
                   from gd
                   group by vendorNumber
                   order by tsd desc
                   limit 10")
top_vendor

top_brands<- sqldf("select brand, sum(totalsalesdollars) as tsd
                   from gd
                   group by brand
                   order by tsd desc
                   limit 10")
top_brands

p1<- ggplot(top_vendor, aes(x= tsd, y = reorder(vendorNumber, tsd)))+
  geom_bar(stat="identity", fill="steelblue")+
  geom_text(aes(label= tsd), hjust= -0.1, color = "black", size=3 )+
  labs(title = "TOP 10 VENDOR BY SALE", x = "SALES", y ="VENDORNO.")+
  theme_minimal()
p1

p2<- ggplot(top_brands, aes(x= tsd, y = reorder(brand, tsd)))+
  geom_bar(stat="identity", fill="tomato")+
  geom_text(aes(label= tsd), hjust= -0.1, color = "black", size=3 )+
  labs(title = "TOP 10 BRANDS BY SALE", x = "SALES", y ="BRAND")+
  theme_minimal()
p2

#vendors contribute the most to total purchase dollars

vendor_performance<-sqldf("select vendorNumber, sum(totalPurchaseDollars) as tpd,
                          sum(GrossProfit) as gp, sum(TotalsalesDollars) as tsd
                          from finaltable
                          group by vendorNumber")
vendor_performance



top_vendors<- sqldf("select vendorNumber, tpd*1.0 / sum(tpd) over() as purchasecontripercent,
                    tpd, gp, tsd
                    from vendor_performance
                    group by vendorNumber
                    order by purchasecontripercent desc
                    limit 10")
top_vendors

top_vendors$cumulativepercent<- cumsum(top_vendors$purchasecontripercent)
print(top_vendors)
View(top_vendors)

#HOW MUCH OF TOTAL PROCUREMENT IS DEPENDENT ON TOP VENDORS

TOPDEPENDENT<- sqldf("select sum(purchasecontripercent)*100 as totalpercent
                       from top_vendors")
TOPDEPENDENT

# VENDORS HAVE LOW INVENTORY TURNOVER INDICATING EXCESS STOCK

vendors<-sqldf("select vendorNumber, stockturnover
               from finaltable
               where stockturnover<1
               group by vendorNumber")

vendors
View(vendors)

#CAPITAL LOCKED IN UNSOLD INVENTORY
finaltable$UNSOLD<- (finaltable$TotalQuantityPurchase- finaltable$TotalSalesQuantity) *
  finaltable$PurchasePrice

finaltable$UNSOLD



