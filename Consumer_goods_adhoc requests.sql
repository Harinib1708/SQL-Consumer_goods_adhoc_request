#Request 1
select distinct market 
from dim_customer
where region = 'APAC' and customer = 'Atliq Exclusive';

#Request 2
with unique_products as (
select fiscal_year,count(distinct product_code) as unique_products
from fact_gross_price
group by fiscal_year )

select 
up_2020.unique_products  as unique_products_2020 ,
up_2021.unique_products  as unique_products_2021 ,
round(100*(up_2021.unique_products - up_2020.unique_products )/ up_2020.unique_products ,2) as percentage_chg
from unique_products up_2020 , unique_products up_2021
where up_2020.fiscal_year = 2020 and  up_2021.fiscal_year = 2021; 

#Request 3
select segment,count(distinct product_code) as product_count
from dim_product
group by segment
order by product_count desc;

#Request 4
with cte as (
select p.segment,s.fiscal_year,
count(distinct s.Product_code) as product_count
from fact_sales_monthly s
join dim_product p on s.product_code = p.product_code
GROUP BY p.segment,s.fiscal_year
)
select up_2020.segment,
up_2020.product_count as product_count_2020,
up_2021.product_count as product_count_2021,
up_2021.product_count - up_2020.product_count as difference
from temp_table as up_2020
join temp_table as up_2021
on up_2020.segment = up_2021.segment and 
up_2020.fiscal_year = 2020 and 
up_2021.fiscal_year = 2021
order by difference desc;

#Request 5
select p.product_code,concat(p.product," - ",p.variant)as product,cost_year,manufacturing_cost
from fact_manufacturing_cost m
join dim_product p
on m.product_code = p.product_code
where manufacturing_cost = 
(select min(manufacturing_cost) from fact_manufacturing_cost )
or
manufacturing_cost =  
(select max(manufacturing_cost) from fact_manufacturing_cost )
order by manufacturing_cost desc;

#Request 6
select  c.customer_code,c.customer,round(avg(pre_invoice_discount_pct),4) as avg_pre_invoice_dis
from fact_pre_invoice_deductions pre
join dim_customer c
on pre.customer_code = c.customer_code
where fiscal_year = 2021 and market = 'india'
group by c.customer_code,c.customer
order by avg_pre_invoice_dis desc
limit 5

#Request 7
with cte as (
select customer,
monthname(date) as months,
month(date) as month_no,
year(date) as year,
(sold_quantity * gross_price)  as gross_sales
from fact_sales_monthly s
join fact_gross_price g
on s.product_code = g.product_code 
join dim_customer c
on s.customer_code = c.customer_code
where customer = "Atliq exclusive")

select months,year, concat(round(sum(gross_sales)/1000000,2),"M") as gross_sales 
from cte
group by  months,month_no,year
order by  year,month_no;

#Request 8
with cte as (
select date,month(date_add(date,interval 4 month)) AS period, fiscal_year,sold_quantity 
from fact_sales_monthly
)
select case
   when period/3 <= 1 then "Q1"
   when period/3 <= 2 and period/3 > 1 then "Q2"
   when period/3 <=3 and period/3 > 2 then "Q3"
   when period/3 <=4 and period/3 > 3 then "Q4" end quarter,
 round(sum(sold_quantity)/1000000,2) as total_sold_qty_mln from cte
where fiscal_year = 2020
group by quarter
order by total_sold_qty_mln  desc ;

#Request 9
with cte as (
select c.channel,sum(sold_quantity*gross_price) as total_sales
from fact_sales_monthly s
join fact_gross_price g
on s.product_code = g.product_code and s.fiscal_year = g.fiscal_year
join dim_customer c
on c.customer_code = s.customer_code 
where g.fiscal_year = 2021
group by c.channel )

select channel,
round(total_sales/1000000,2) as gross_sales_mln,
round(total_sales*100/sum(total_sales)over() ,2)as pct
 from cte
 
#Request 10
with cte as (
select p.division,s.product_code,p.product,sum(sold_quantity) as sold_qty,
rank() over(partition by p.division order by sum(sold_quantity) desc ) as rnk
from fact_sales_monthly s
join dim_product p
on s.product_code = p.product_code
where fiscal_year=2021
group by p.division,s.product_code,p.product)

select *
from cte
where rnk<=3;















