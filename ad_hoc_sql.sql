/* 1.  Provide the list of markets in which customer  "Atliq  Exclusive"  operates its 
business in the  APAC  region. */

select market from dim_customer
where customer  Like "%Atliq Exclusive%"
and region like "%APAC%";

/* 2.  What is the percentage of unique product increase in 2021 vs. 2020? The 
final output contains these fields, 
unique_products_2020 
unique_products_2021 
percentage_chg */

with cte1 as( select count(distinct product_code) as unique_products_2020 from fact_sales_monthly
where fiscal_year = 2020),
cte2 as(select count(distinct product_code) as unique_products_2021 from fact_sales_monthly
where fiscal_year = 2021)
select cte2.unique_products_2021, cte1.unique_products_2020,
((cte2.unique_products_2021 - cte1.unique_products_2020)*100/
cte1.unique_products_2020)
as percentage_chg from cte1, cte2;

/* 3.  Provide a report with all the unique product counts for each  segment  and 
sort them in descending order of product counts. The final output contains 
2 fields, 
segment 
product_count */

select segment, count(product) as product_count from dim_product
group by segment
order by product_count desc;

/* 4.  Follow-up: Which segment had the most increase in unique products in 
2021 vs 2020? The final output contains these fields, 
segment 
product_count_2020 
product_count_2021 
difference */

with cte1 as (select p.segment, count(distinct s.product_code) as product_count_2021
from fact_sales_monthly s
join dim_product p
on s.product_code = p.product_code
where fiscal_year = 2021
group by p.segment),
cte2 as (select p.segment, count(distinct s.product_code) as product_count_2020 
from fact_sales_monthly s
join dim_product p
on s.product_code = p.product_code
where fiscal_year = 2020
group by p.segment)

select cte1.segment as segment, product_count_2021, product_count_2020,
(product_count_2021-product_count_2020) as difference
 from cte1
join cte2
on cte1.segment = cte2.segment
order by difference desc;

/* 5.  Get the products that have the highest and lowest manufacturing costs. 
The final output should contain these fields, 
product_code 
product 
manufacturing_cost */
(select p.product, m.product_code, m.manufacturing_cost
 from fact_manufacturing_cost m
join dim_product p
on m.product_code = p.product_code
order by m.manufacturing_cost desc
limit 1)
union
(select p.product, m.product_code, m.manufacturing_cost
 from fact_manufacturing_cost m
join dim_product p
on m.product_code = p.product_code
order by m.manufacturing_cost
limit 1);

/* 6.  Generate a report which contains the top 5 customers who received an 
average high  pre_invoice_discount_pct  for the  fiscal  year 2021  and in the 
Indian  market. The final output contains these fields, 
customer_code 
customer 
average_discount_percentage */

select i.customer_code, c.customer, avg( pre_invoice_discount_pct) as average_discount_percentage
from fact_pre_invoice_deductions i
join dim_customer c
on i.customer_code = c.customer_code
where fiscal_year = 2021 and market like "%India%"
group by i.customer_code, c.customer
order by average_discount_percentage desc
limit 5;

/* 7.  Get the complete report of the Gross sales amount for the customer  “Atliq 
Exclusive”  for each month  .  This analysis helps to  get an idea of low and 
high-performing months and take strategic decisions. 
The final report contains these columns: 
Month 
Year 
Gross sales Amount */
select month(date) as Month, s.fiscal_year as year, round(sum(s.sold_quantity*g.gross_price),2)  as gross_sales_amount
from fact_gross_price g
join fact_sales_monthly s
on g.product_code = s.product_code
and g.fiscal_year = s.fiscal_year
join dim_customer c
on s.customer_code = c.customer_code
where c.customer like "%Atliq Exclusive%"
and s.fiscal_year in (2020,2021)
group by year, Month
order by Gross_sales_amount desc, year;

/* 8.  In which quarter of 2020, got the maximum total_sold_quantity? The final 
output contains these fields sorted by the total_sold_quantity, 
Quarter 
total_sold_quantity */

select CASE
        WHEN MONTH(date) in (9,10,11) THEN 'Q1'
        WHEN MONTH(date) in (12,1,2) THEN 'Q2'
        WHEN MONTH(date) in (3,4,5) THEN 'Q3'
        else 'Q4' 
    END AS Quarter, sum(sold_quantity) as Total_sold_quantity from fact_sales_monthly
where fiscal_year = 2020
group by Quarter
order by Total_sold_quantity desc;

/* 9.  Which channel helped to bring more gross sales in the fiscal year 2021 
and the percentage of contribution?  The final output  contains these fields, 
channel 
gross_sales_mln 
percentage */

with cte as (select c.channel,  round((sum(s.sold_quantity*g.gross_price)/1000000),2) as gross_sales_mln
from fact_sales_monthly s
join fact_gross_price g
on g.product_code = s.product_code
join dim_customer c
on s.customer_code = c.customer_code
and s.fiscal_year = 2021
group by channel)
select *,gross_sales_mln*100/sum(gross_sales_mln) over() as percentage from cte
group by channel
order by gross_sales_mln desc;


/* 10.  Get the Top 3 products in each division that have a high 
total_sold_quantity in the fiscal_year 2021? The final output contains these 
fields, 
division 
product_code  */

with cte1 as (select s.product_code, p.product, p.division, sum(s.sold_quantity) as total_sold_quantity 
from fact_sales_monthly s
join dim_product p
on s.product_code = p.product_code
where fiscal_year = 2021
group by p.division, s.product_code),
cte2 as (select *, 
rank() over(partition by division order by total_sold_quantity desc) as rnk
from cte1)
select cte1.division, cte1.product_code,cte1.product, cte2.total_sold_quantity 
from cte2 join cte1 on cte1.product_code = cte2.product_code
where rnk in (1,2,3);






















