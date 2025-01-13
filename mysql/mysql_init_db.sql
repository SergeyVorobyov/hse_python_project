/* 1. Users, пользователи:   
user_id — уникальный идентификатор пользователя;  
first_name — имя пользователя;   
last_name — фамилия пользователя;   
email — электронная почта;   
phone — номер телефона;   
registration_date — дата регистрации пользователя;   
loyalty_status — статус лояльности: Gold, Silver и пр. 
 */

CREATE TABLE IF NOT EXISTS users (
    user_id INT PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(100),
    registration_date DATE,
    loyalty_status VARCHAR(30)
);




/*5. ProductCategories, категории товаров:  
category_id — уникальный идентификатор категории;   
name — название категории;   
parent_category_id — идентификатор родительской категории, его может не быть.
*/

CREATE TABLE IF NOT EXISTS productcategories (
    category_id INT PRIMARY KEY,
    name VARCHAR(100),
    parent_category_id INT
);



/*  2. Products, товары:    
product_id — уникальный идентификатор товара;   
name — название товара;   
description — описание товара;   
category_id — идентификатор категории товара;   
price — цена товара;   
stock_quantity — количество товара на складе;   
creation_date — дата добавления товара. 
 */

CREATE TABLE IF NOT EXISTS products (
    product_id INT PRIMARY KEY,
    name VARCHAR(100),
    description VARCHAR(500),
    category_id INT,
    price DECIMAL(12, 2),
    stock_quantity INT,
    creation_date DATE
);



/* 3. Orders, заказы:   
order_id — уникальный идентификатор заказа;   
user_id — идентификатор пользователя, который сделал заказ;   
order_date — дата и время создания заказа;   
total_amount — общая сумма заказа;   
status — статус заказа: Pending, Completed и т. д.;   
delivery_date — дата доставки заказа. 
 */

CREATE TABLE IF NOT EXISTS orders (
    order_id INT PRIMARY KEY,
    user_id INT,
    order_date TIMESTAMP,
    total_amount DECIMAL(12, 2),
    status VARCHAR(30),
    delivery_date DATE
);



/* 4. OrderDetails, детали заказов:   
order_detail_id — уникальный идентификатор детали заказа;  
order_id — идентификатор заказа;   
product_id — идентификатор товара;   
quantity — количество товара в заказе;   
price_per_unit — цена за единицу товара;  
total_price — общая стоимость товара в заказе, количество товаров, умноженное на цену единицы товара. 
 */

CREATE TABLE IF NOT EXISTS order_details (
    order_detail_id INT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT,
    price_per_unit DECIMAL(12, 2),
    total_price DECIMAL(14, 2)
);



/* простая RFM-витрина в виде вью 
  по каждому пользователю находим:
  - число дней с момента последнего заказа (recency)
  - общее число сделанных завершенных заказов (frequency)
  - общую сумму завершенных заказов (monetary_value)
 */
create view vw_rfm_clients_report as 
SELECT 
u.user_id, 
u.first_name,
u.last_name,
u.loyalty_status,
coalesce(min(datediff(CURRENT_DATE() , cast(o.order_date as date))), 10000) as recency,
sum(case when o.status = 'Completed' then 1 else 0 end) as frequency,
sum(case when o.status = 'Completed' then total_amount  else 0.0 end) as monetary_value
from users as u
left join orders as o
on u.user_id  = o.user_id 
group by
u.user_id, 
u.first_name,
u.last_name,
u.loyalty_status
order by u.loyalty_status, u.last_name
;
