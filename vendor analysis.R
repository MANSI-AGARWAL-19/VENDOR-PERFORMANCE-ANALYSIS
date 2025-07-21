begin_inventory <- read.csv("E:\\vendor\\begin_inventory.csv")
end_inventory <- read.csv("E:\\vendor\\end_inventory.csv")
purchase_prices <- read.csv("E:\\vendor\\purchase_prices.csv")
purchases <- read.csv("E:\\vendor\\purchases.csv")
vendor_invoices <-read.csv("E:\\vendor\\vendor_invoice.csv")
sales <-read.csv("E:\\vendor\\sales.csv")
install.packages("sqldf")
library(sqldf)
View(vendor_invoices)
vendorcount<-sqldf("SELECT COUNT(*) FROM vendor_invoices")
View(vendorcount)
vendorcount
View(begin_inventory)
View(end_inventory)
View(purchase_prices)
View(purchases)
display<-sqldf("select * from begin_inventory
               limit 5;")
display
View(sales)

purchases1<-sqldf("select * from purchases where vendornumber= 4466;")
purchases1

purchase_prices1<-sqldf("select * from purchase_prices where vendornumber=4466;")
purchase_prices1

vendor_invoices1<-sqldf("select * from vendor_invoices where vendornumber=4466;")
vendor_invoices1

sales1<-sqldf("select * from sales where vendorNo=4466;")
sales1

purchases2<-sqldf("select Brand, PurchasePrice, sum(quantity), sum(dollars) 
from purchases1
                  group by brand;")
purchases2

sales2<-sqldf("select Brand, sum(SalesDollars), sum(SalesPrice), sum(SalesQuantity)
              from sales1
              group by brand;")
sales2

freight_summary<-sqldf("select vendorNumber, sum(freight) as freightCost
                       from vendor_invoices
                       group by vendorNumber
                       ;")
freight_summary

summaryvendor<-sqldf("select p.vendorNumber, p.vendorName, p.brand, p.PurchasePrice,
               pp.volume, pp.Price as ActualPrice,
               sum(p.Quantity) as TotalQuantityPurchase,
               sum(p.Dollars) as TotalPurchaseDollars
               from purchases p
                join purchase_prices pp
               on p.brand = pp.brand
               where p.PurchasePrice > 0
               group by p.VendorNumber, p.VendorName, p.Brand
               order by TotalPurchaseDollars;")
summaryvendor

salessummary<-sqldf("select VendorNo, Brand, sum(salesdollars) as
                    totalsalesdollars, sum(salesprice) as totalsalesprice, 
                    sum(salesquantity) as totalsalesquantity,
                    sum(excisetax) as totalexcisetax
                    from sales
                    group by VendorNo, Brand;")
salessummary


finaltable<-sqldf(" with freight_summary as (
              select 
                vendorNumber,
                sum(freight) as freightCost
                        from vendor_invoices
                        group by vendorNumber
                 ),
                 summaryvendor as (
                 select
                 p.vendorNumber,
                 p.vendorName, 
                 p.brand, 
                 p.PurchasePrice,
                pp.volume, 
                pp.Price as ActualPrice,
                sum(p.Quantity) as TotalQuantityPurchase,
                sum(p.Dollars) as TotalPurchaseDollars
                from purchases p
                 join purchase_prices pp
                on p.brand = pp.brand
                where p.PurchasePrice > 0
                group by p.VendorNumber, p.VendorName, p.Brand
                order by TotalPurchaseDollars 
                 ),
                 salessummary as(
                 select
                 VendorNo, Brand, 
                 sum(salesdollars) as
                     totalsalesdollars,
                     sum(salesprice) as totalsalesprice, 
                     sum(salesquantity) as totalsalesquantity,
                     sum(excisetax) as totalexcisetax
                     from sales
                     group by VendorNo, Brand
                 ),
          select 
             sn.vendornumber, 
             sn.brand,  
             sn.purchaseprice, 
             sn.actualprice,
                   ss.totalsalesquantity, 
                   ss.totalsalesdollars,
                    ss.totalsalesprice, 
                   ss.totalexcisetax,
                   sn.totalquantitypurchase, 
                   sn.totalpurchasedollars,
                   fs.freightcost
                    from summaryvendor sn
                    left join salessummary ss
                    on sn.vendornumber = ss.vendorno
                    and sn.brand = ss.brand
                   left join freight_summary fs
                    on sn.vendornumber = fs.vendornumber")

                   
finaltable <- sqldf("
  WITH freight_summary AS (
    SELECT 
      vendorNumber,
      SUM(freight) AS freightCost
    FROM vendor_invoices
    GROUP BY vendorNumber
  ),
  summaryvendor AS (
    SELECT
      p.vendorNumber,
      p.vendorName, 
      p.brand, 
      p.PurchasePrice,
      pp.volume, 
      pp.Price AS ActualPrice,
      SUM(p.Quantity) AS TotalQuantityPurchase,
      SUM(p.Dollars) AS TotalPurchaseDollars
    FROM purchases p
    JOIN purchase_prices pp
      ON p.brand = pp.brand
    WHERE p.PurchasePrice > 0
    GROUP BY p.vendorNumber, p.vendorName, p.brand, p.PurchasePrice, pp.volume, pp.Price
  ),
  salessummary AS (
    SELECT
      VendorNo, 
      Brand, 
      SUM(salesdollars) AS TotalSalesDollars,
      SUM(salesprice) AS TotalSalesPrice, 
      SUM(salesquantity) AS TotalSalesQuantity,
      SUM(excisetax) AS TotalExciseTax
    FROM sales
    GROUP BY VendorNo, Brand
  )

  SELECT 
    sn.vendorNumber, 
    sn.brand,  
    sn.PurchasePrice, 
    sn.ActualPrice,
    ss.TotalSalesQuantity, 
    ss.TotalSalesDollars,
    ss.TotalSalesPrice, 
    ss.TotalExciseTax,
    sn.TotalQuantityPurchase, 
    sn.TotalPurchaseDollars,
    fs.freightCost
  FROM summaryvendor sn
  LEFT JOIN salessummary ss
    ON sn.vendorNumber = ss.VendorNo AND sn.brand = ss.Brand
  LEFT JOIN freight_summary fs
    ON sn.vendorNumber = fs.vendorNumber
  ORDER BY sn.TotalPurchaseDollars DESC
")
finaltable
View(finaltable)


str(finaltable)

colSums(is.na(finaltable))

finaltable[is.na(finaltable)] <- 0
finaltable
View(finaltable)

finaltable$GrossProfit<- finaltable$TotalSalesDollars - finaltable$TotalPurchaseDollars
finaltable

finaltable$profitmargin<- (finaltable$GrossProfit/ finaltable$TotalSalesDollars)*100
finaltable

finaltable$stockturnover<- finaltable$TotalSalesQuantity /finaltable$TotalQuantityPurchase
finaltable

finaltable$salestoPurchaseRatio<- finaltable$TotalSalesDollars / finaltable$TotalPurchaseDollars
finaltable



write.csv(finaltable, "finaltable.csv", row.names = FALSE)
getwd()


