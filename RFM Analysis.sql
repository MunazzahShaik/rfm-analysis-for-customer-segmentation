select *  from MyProjectPortfolio..SalesData


--Checking unique values
select distinct status from MyProjectPortfolio..SalesData
select distinct YEAR_ID from MyProjectPortfolio..SalesData 
select distinct PRODUCTLINE from MyProjectPortfolio..SalesData 
select distinct COUNTRY from MyProjectPortfolio..SalesData
select distinct DEALSIZE from MyProjectPortfolio..SalesData
select distinct TERRITORY from MyProjectPortfolio..SalesData

--Analysing the Data

--Finding the sales per product line
select Productline,sum(sales) Revenue
from MyProjectPortfolio..SalesData
group by PRODUCTLINE
order by 2 desc

-- Year wise sales
select YEAR_ID,sum(sales) Revenue
from MyProjectPortfolio..SalesData
group by YEAR_ID
order by 2 desc

-- Revenue for different deal sizes
select DEALSIZE,sum(sales) Revenue
from MyProjectPortfolio..SalesData
group by DEALSIZE
order by 2 desc

--Best Months for sale in a year
select Month_ID, sum(sales) Revenue, count(ordernumber) Frequency
from MyProjectPortfolio..SalesData
where Year_ID = 2004
group by Month_ID
order by 2 desc

--November is the best Month for sales. Checking the products sold in November.
select Month_ID, Productline, sum(sales) Revenue, count(ordernumber) Frequency
from MyProjectPortfolio..SalesData
where Year_ID = 2004 and MONTH_ID = 11
group by Month_ID, PRODUCTLINE
order by 3 desc

--Finding out our best Customer
--RFM Analysis : (Recency - Last order Data, Frequency - Count of total orders, Monetary value : Total Spend)
Drop table if exists #rfm
;with RFM as
(
select 
  CUSTOMERNAME, 
  sum(sales) MonetaryValue, 
  avg(sales) AvgMonetaryValue,
  count(ordernumber) Frequency, 
  max(orderdate) LastOrderDate, 
  (select max(orderdate) from MyProjectPortfolio..SalesData) MaxOrderDate, 
  DATEDIFF(DD,max(orderdate), (select max(orderdate) from MyProjectPortfolio..SalesData)) Recency
from MyProjectPortfolio..SalesData 
group by CUSTOMERNAME
),
--Creating Buckets 
rfm_calc as 
(
select r.*,
  NTILE(4) over (order by recency) RFM_Recency,
  NTILE(4) over (order by frequency) RFM_Frequency,
  NTILE(4) over (order by AvgMonetaryValue) RFM_Monetary
from rfm r
)
select c.*,RFM_Recency + RFM_Frequency + RFM_Monetary as rfm_cell,
cast(rfm_recency as varchar) + cast(RFM_Frequency as varchar) + cast(rfm_Monetary as varchar) RFM_CELL_STRING
into #rfm
from rfm_calc c

select * from #rfm

select CUSTOMERNAME,RFM_Recency,RFM_Frequency,RFM_Monetary,
  case
when RFM_CELL_STRING in (111,112,121,122,123,132,211,212,114,141) then 'Lost Customers'
when RFM_CELL_STRING in (133,134,143,244,334,343,344) then 'Slipping away, Cannot lose'
when RFM_CELL_STRING in (311,411,331) then 'New Customers'
when RFM_CELL_STRING in (222,223,233,322) then 'Potential Churners'
when RFM_CELL_STRING in (323,333,321,422,332,432) then 'Active'
when RFM_CELL_STRING in (433,434,443,444) then 'Loyal'
  end rfm_segment
from #rfm

-- What products are most often sold together?
select productcode from MyProjectPortfolio..salesdata
where ordernumber in
(
select ordernumber from
(
select ORDERNUMBER, count(*) rn            
from MyProjectPortfolio..SalesData
where STATUS = 'shipped'
group by ORDERNUMBER
)m
where rn =2
)