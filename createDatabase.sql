CREATE DATABASE storeSite
GO

USE storeSite
GO
CREATE SCHEMA stageArea 
GO 

DROP TABLE stageArea.click_stream;
CREATE TABLE stageArea.click_stream (
session_id_ UNIQUEIDENTIFIER, 
event_name varchar(15), 
event_time datetime2,
event_id UNIQUEIDENTIFIER, 
traffic_source varchar(10),
event_metadata varchar(60),
);

DROP TABLE stageArea.customer;

CREATE TABLE stageArea.customer (
customer_id INT, 
first_name VARCHAR(20), 
last_name VARCHAR(20), 
username UNIQUEIDENTIFIER,
email VARCHAR(60),
gender CHAR(1),
birthdate DATE, 
device_type VARCHAR(7),
device_id UNIQUEIDENTIFIER,
device_version VARCHAR(60),
home_location_lat FLOAT,
home_location_long FLOAT,
home_location VARCHAR(50),
home_country VARCHAR(10),
first_join_date DATE
);

DROP TABLE stageArea.product;
CREATE TABLE stageArea.product (
id INT, 
gender VARCHAR(10), 
masterCategory VARCHAR(20), 
subCategory VARCHAR(30), 
articleType VARCHAR(30), 
baseColour VARCHAR(20), 
season VARCHAR(10), 
yearReg INT,
usage VARCHAR(20), 
productDisplayName VARCHAR(100)
);

DROP TABLE stageArea.transactions;
CREATE TABLE stageArea.transactions (
created_at datetime2,
customer_id INT,
booking_id UNIQUEIDENTIFIER,
session_id_ UNIQUEIDENTIFIER,
payment_method varchar(12),
payment_status varchar(7),
promo_amount INT, 
promo_code varchar(15),
shipment_fee INT,
shipment_date_limit datetime2,
shipment_location_lat FLOAT,
shipment_location_long FLOAT,
total_amount INT,
product_id INT,
quantity INT,
item_price INT
);

DROP TABLE stageArea.transaction_base;
DROP TABLE stageArea.transaction_new;

--CREATE TABLE stageArea.transaction_new (
--created_at datetime2,
--customer_id INT,
--booking_id UNIQUEIDENTIFIER,
--session_id_ UNIQUEIDENTIFIER,
--payment_method varchar(12),
--payment_status varchar(7),
--promo_amount INT, 
--promo_code varchar(15),
--shipment_fee INT,
--shipment_date_limit datetime2
--);



GO
CREATE SCHEMA warehouse
GO 

CREATE TABLE warehouse.dim_event_name (
event_name_id  INT IDENTITY (1,1) PRIMARY KEY,
event_name_value  varchar(15)
)

CREATE TABLE warehouse.dim_attributes (
event_data_id  INT IDENTITY (1,1) PRIMARY KEY,
event_name INT,
product_id INT,
quantity INT ,
item_price INT,
payment_status varchar(7),
promo_code varchar(15),
promo_amount int,
search_keywords varchar (50),
CONSTRAINT FK_event_name FOREIGN KEY (event_name)
    REFERENCES warehouse.dim_event_name(event_name_id)
)

CREATE TABLE  warehouse.dim_time (
    time_id INT IDENTITY(1,1) PRIMARY KEY,
    [year] INT,
    [month] INT,
    [day] INT
);

CREATE TABLE warehouse.dim_traffic_source (
traffic_id  INT IDENTITY (1,1) PRIMARY KEY,
traffic_name  varchar(15)
)

CREATE TABLE warehouse.fact_click_stream (
event_id UNIQUEIDENTIFIER PRIMARY KEY, 
sesion_id UNIQUEIDENTIFIER, 
event_attributes int, 
event_date int,
traffic_source int,
event_time time,
CONSTRAINT FK_event_attributes FOREIGN KEY (event_attributes)
    REFERENCES warehouse.dim_attributes(event_data_id),
CONSTRAINT FK_event_time FOREIGN KEY (event_date)
    REFERENCES warehouse.dim_time(time_id),
CONSTRAINT FK_event_traffic FOREIGN KEY (traffic_source)
    REFERENCES warehouse.dim_traffic_source(traffic_id)
);


CREATE TABLE warehouse.dim_device_type (
dev_type_id  INT IDENTITY (1,1) PRIMARY KEY,
dev_type_name  VARCHAR(7)
)

CREATE TABLE warehouse.dim_device_version (
version_id  INT IDENTITY (1,1) PRIMARY KEY,
version_name  VARCHAR(60)
)

CREATE TABLE warehouse.dim_town (
town_id  INT IDENTITY (1,1) PRIMARY KEY,
town_name  VARCHAR(50)
)

CREATE TABLE warehouse.dim_home (
home_id INT IDENTITY (1,1) PRIMARY KEY,
home_location_lat FLOAT,
home_location_long FLOAT,
home_location INT,
home_country VARCHAR(10),
CONSTRAINT FK_customer_home_town FOREIGN KEY (home_location)
    REFERENCES warehouse.dim_town(town_id),
)


CREATE TABLE warehouse.dim_customer (
customer_key INT IDENTITY (1,1) PRIMARY KEY,
customer_id INT, 
first_name VARCHAR(20), 
last_name VARCHAR(20), 
username UNIQUEIDENTIFIER,
email VARCHAR(60),
gender CHAR(1),
device_type INT,
device_id UNIQUEIDENTIFIER,
device_version INT,
home INT,
previous_id INT DEFAULT NULL,
birthdate INT,
first_join_date INT, 
CONSTRAINT FK_customer_device_type FOREIGN KEY (device_type)
    REFERENCES warehouse.dim_device_type(dev_type_id),
CONSTRAINT FK_customer_device_version FOREIGN KEY (device_version)
    REFERENCES warehouse.dim_device_version(version_id),
CONSTRAINT FK_customer_home FOREIGN KEY (home)
    REFERENCES warehouse.dim_home(home_id),
CONSTRAINT FK_previous FOREIGN KEY (previous_id)
    REFERENCES warehouse.dim_customer(customer_key)
);

alter table warehouse.dim_customer
add constraint FK_customer_birthdate foreign key (birthdate)
references warehouse.dim_time(time_id)
go

alter table warehouse.dim_customer
add constraint FK_customer_first_join_date foreign key (first_join_date)
references warehouse.dim_time(time_id)
go


CREATE TABLE warehouse.dim_gender (
gender_id  INT IDENTITY (1,1) PRIMARY KEY,
gender_name  VARCHAR(10)
)

CREATE TABLE warehouse.dim_masterCategory (
masterCategory_id  INT IDENTITY (1,1) PRIMARY KEY,
masterCategory_name  VARCHAR(20)
)

CREATE TABLE warehouse.dim_subCategory (
subCategory_id  INT IDENTITY (1,1) PRIMARY KEY,
subCategory_name  VARCHAR(30)
)

CREATE TABLE warehouse.dim_articleType (
articleType_id  INT IDENTITY (1,1) PRIMARY KEY,
articleType_name  VARCHAR(30)
)

CREATE TABLE warehouse.dim_baseColour (
baseColour_id  INT IDENTITY (1,1) PRIMARY KEY,
baseColour_name  VARCHAR(20)
)

CREATE TABLE warehouse.dim_season (
season_id  INT IDENTITY (1,1) PRIMARY KEY,
season_name  VARCHAR(10)
)

CREATE TABLE warehouse.dim_usage (
usage_id  INT IDENTITY (1,1) PRIMARY KEY,
usage_name  VARCHAR(20)
)

CREATE TABLE warehouse.dim_product (
product_key INT IDENTITY (1,1) PRIMARY KEY,
id INT, 
gender INT, 
masterCategory INT, 
subCategory INT, 
articleType INT, 
baseColour INT, 
season INT, 
yearReg INT,
usage INT, 
productDisplayName VARCHAR(100),
previous_id INT DEFAULT NULL,
CONSTRAINT FK_product_gender FOREIGN KEY (gender)
    REFERENCES warehouse.dim_gender(gender_id),
CONSTRAINT FK_product_subCategory FOREIGN KEY (subCategory)
    REFERENCES warehouse.dim_subCategory(subCategory_id),
CONSTRAINT FK_product_masterCategory FOREIGN KEY (masterCategory)
    REFERENCES warehouse.dim_masterCategory(masterCategory_id),
CONSTRAINT FK_product_baseColour FOREIGN KEY (baseColour)
    REFERENCES warehouse.dim_baseColour(baseColour_id),
CONSTRAINT FK_product_season FOREIGN KEY (season)
    REFERENCES warehouse.dim_season(season_id),
CONSTRAINT FK_product_usage FOREIGN KEY (usage)
    REFERENCES warehouse.dim_usage(usage_id),
CONSTRAINT FK_previous_prod FOREIGN KEY (previous_id)
    REFERENCES warehouse.dim_product(product_key)
);


alter table warehouse.dim_product
add constraint FK_product_article_type foreign key (articleType)
references warehouse.dim_articleType(articleType_id)
go

CREATE TABLE warehouse.dim_payment_method (
method_id  INT IDENTITY (1,1) PRIMARY KEY,
method_name  VARCHAR(12)
)

CREATE TABLE warehouse.dim_payment_status (
status_id  INT IDENTITY (1,1) PRIMARY KEY,
status_name  VARCHAR(12)
)

CREATE TABLE warehouse.dim_promo_code (
code_key INT IDENTITY (1,1) PRIMARY KEY,
code_name  VARCHAR(15),
previous_id INT DEFAULT NULL,
CONSTRAINT FK_previous_code FOREIGN KEY (previous_id)
    REFERENCES warehouse.dim_promo_code(code_key)
)


CREATE TABLE warehouse.fact_transactions (
booking_id UNIQUEIDENTIFIER PRIMARY KEY,
created_at INT,
customer_key INT,
session_id_ UNIQUEIDENTIFIER,
payment_method INT,
payment_status INT,
promo_amount INT, 
promo_code INT,
shipment_fee INT,
shipment_date_limit INT,
shipment_location_lat FLOAT,
shipment_location_long FLOAT,
total_amount INT,
shipment_time_limit TIME,
created_at_time TIME,
CONSTRAINT FK_transactions_time FOREIGN KEY (created_at)
    REFERENCES warehouse.dim_time(time_id),
CONSTRAINT FK_transactions_customer FOREIGN KEY (customer_key)
    REFERENCES warehouse.dim_customer(customer_key),
CONSTRAINT FK_transactions_payment_method FOREIGN KEY (payment_method)
    REFERENCES warehouse.dim_payment_method(method_id),
CONSTRAINT FK_transactions_payment_status FOREIGN KEY (payment_status)
    REFERENCES warehouse.dim_payment_status(status_id),
CONSTRAINT FK_transactions_promo_code FOREIGN KEY (promo_code)
    REFERENCES warehouse.dim_promo_code(code_key),
CONSTRAINT FK_transactions_shipment_time FOREIGN KEY (shipment_date_limit)
    REFERENCES warehouse.dim_time(time_id)
);

CREATE TABLE warehouse.dim_transactions_product(
id  INT IDENTITY (1,1) PRIMARY KEY,
transactions UNIQUEIDENTIFIER,
product INT, 
quantity INT,
item_price INT, 
CONSTRAINT FK_transactions FOREIGN KEY (transactions)
    REFERENCES warehouse.fact_transactions(booking_id),
CONSTRAINT FK_product FOREIGN KEY (product)
    REFERENCES warehouse.dim_product(product_key)
)


