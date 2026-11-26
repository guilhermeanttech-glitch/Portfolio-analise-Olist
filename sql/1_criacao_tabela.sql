CREATE DATABASE DBOlist;
USE DBOlist;

CREATE TABLE customers (
	customer_id VARCHAR(50) PRIMARY KEY,
   customer_unique_id VARCHAR(50) NOT NULL,
   customer_zip_code_prefix VARCHAR(5),
   customer_city VARCHAR(50),
   customer_state CHAR(2)
);

CREATE TABLE orders (
	order_id VARCHAR(50) PRIMARY KEY,
   customer_id VARCHAR(50) NOT NULL,
   order_status VARCHAR(30),
   order_purchase_timestamp DATETIME,
   order_approved_at DATETIME,
   order_delivered_carrier_date DATETIME,
   order_delivered_customer_date DATETIME,
   order_estimated_delivery_date DATETIME	
);

CREATE TABLE order_items (
	order_id VARCHAR(50) NOT NULL,
	order_item_id INT NOT NULL,
   product_id VARCHAR(50) NOT NULL,
   seller_id VARCHAR(50) NOT NULL,
   shipping_limit_date DATETIME,
   price DECIMAL(10,2),    
	freight_value DECIMAL(10,2),
   PRIMARY KEY(order_id, order_item_id)
);

CREATE TABLE order_payments (
	order_id VARCHAR(50) NOT NULL,
   payment_sequential INT NOT NULL,
   payment_type VARCHAR(30) NOT NULL,
   payment_installments INT NOT NULL,
   payment_value DECIMAL(13,2) NOT NULL,
   PRIMARY KEY (order_id, payment_sequential)
);

CREATE TABLE order_reviews (
	review_id VARCHAR(50) NOT NULL,
   order_id VARCHAR(50) NOT NULL,
   review_score TINYINT,
   review_comment_title VARCHAR(100),
   review_comment_message VARCHAR(500),
   review_creation_date DATETIME,
   review_answer_timestamp DATETIME
);

CREATE TABLE products (
	product_id VARCHAR(50) PRIMARY KEY,
   product_category_name VARCHAR(90),
   product_name_length INT,
   product_description_length INT,
   product_photos_qty INT,
   product_weight_g INT,
   product_length_cm INT,
   product_height_cm INT,
   product_width_cm INT
);

CREATE TABLE categories (
   product_category_name VARCHAR(90) PRIMARY KEY,
   product_category_name_english VARCHAR(90)
);

CREATE TABLE sellers (
   seller_id VARCHAR(50) PRIMARY KEY,
   seller_zip_code_prefix VARCHAR(5),
   seller_city VARCHAR(50),
   seller_state CHAR(2)
);