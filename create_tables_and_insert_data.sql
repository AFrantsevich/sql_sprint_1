CREATE DATABASE sprint_1;

CREATE SCHEMA raw_data;

CREATE TABLE raw_data.sales(
    id int2,
    auto varchar(100),
    gasoline_consumption real,
    price numeric(9, 2),
    date date,
    person_name varchar(100), 
    phone varchar(100),
    discount int2,
    brand_origin varchar(50));

COPY raw_data.sales
FROM '/usr/local/share/cars.csv'
WITH CSV HEADER NULL 'null';

CREATE SCHEMA car_shop;

CREATE TABLE car_shop.clients(
    id SERIAL PRIMARY KEY,
    first_name varchar(100) NOT NULL,
    middle_name varchar(100) DEFAULT NULL,
    last_name varchar(100) NOT NULL,
    phone varchar(100) DEFAULT NULL,
    title varchar(50) DEFAULT NULL,
    abbreviation varchar(50) DEFAULT NULL,
    CONSTRAINT unique_person UNIQUE(first_name, last_name, phone));

CREATE TABLE car_shop.brand_origins(
    id SERIAL PRIMARY KEY,
    brand_origin varchar(100) NOT NULL);

CREATE TABLE car_shop.car_colors(
    id SERIAL PRIMARY KEY,
    color varchar(100) NOT NULL);

CREATE TABLE car_shop.car_brands(
    id SERIAL PRIMARY KEY,
    brand varchar(100) NOT NULL,
    brand_origin_id int REFERENCES car_shop.brand_origins DEFAULT NULL);

CREATE TABLE car_shop.car_models(
    id SERIAL PRIMARY KEY,
    brand_id int REFERENCES car_shop.car_brands NOT NULL,
    model varchar(100) NOT NULL,
    gasoline_consumption real DEFAULT NULL);

CREATE TABLE car_shop.cars(
    id SERIAL PRIMARY KEY,
    model_id int REFERENCES car_shop.car_models NOT NULL,
    color_id int REFERENCES car_shop.car_colors NOT NULL);

CREATE TABLE car_shop.sales(
    id SERIAL PRIMARY KEY,
    car_id int REFERENCES car_shop.cars NOT NULL,
    client_id int REFERENCES car_shop.clients NOT NULL,
    date date NOT NULL DEFAULT current_date,
    price numeric(9, 2) NOT NULL,
    discount int2 DEFAULT 0);

INSERT INTO car_shop.brand_origins(
    brand_origin)
SELECT
    DISTINCT
    raw_data.sales.brand_origin
FROM raw_data.sales
WHERE raw_data.sales.brand_origin IS NOT NULL;

INSERT INTO car_shop.car_colors(
    color)
SELECT
    DISTINCT
    SPLIT_PART(raw_data.sales.auto, ',', 2)
FROM raw_data.sales;

INSERT INTO car_shop.car_brands(
    brand,
    brand_origin_id)
SELECT
    DISTINCT
    SPLIT_PART(raw_data.sales.auto, ' ', 1),
    car_shop.brand_origins.id
FROM raw_data.sales
LEFT JOIN car_shop.brand_origins
    ON (car_shop.brand_origins.brand_origin = raw_data.sales.brand_origin);

INSERT INTO car_shop.car_models(
    brand_id,
    model,
    gasoline_consumption)
SELECT
    DISTINCT
    car_shop.car_brands.id,
    LTRIM(SPLIT_PART(raw_data.sales.auto, ',', 1), SPLIT_PART(raw_data.sales.auto, ' ', 1)),
    raw_data.sales.gasoline_consumption
FROM raw_data.sales
LEFT JOIN car_shop.car_brands
    ON (car_shop.car_brands.brand = SPLIT_PART(raw_data.sales.auto, ' ', 1));

INSERT INTO car_shop.cars(
    model_id,
    color_id)
SELECT
    DISTINCT
    car_shop.car_models.id,
    car_shop.car_colors.id
FROM raw_data.sales
LEFT JOIN car_shop.car_colors ON car_shop.car_colors.color =  SPLIT_PART(raw_data.sales.auto, ',', 2)
LEFT JOIN (car_shop.car_models
    LEFT JOIN car_shop.car_brands ON car_shop.car_models.brand_id = car_shop.car_brands.id)
ON CONCAT(SPLIT_PART(raw_data.sales.auto, ' ', 1), ' ', LTRIM(SPLIT_PART(raw_data.sales.auto, ',', 1),
    SPLIT_PART(raw_data.sales.auto, ' ', 1))) = CONCAT(car_shop.car_brands.brand, ' ', car_shop.car_models.model);

-- Заполняем таблицу клиентами у которых только Имя и Фамилия. Без доп. обращений и т.д.
INSERT INTO car_shop.clients(
    first_name,
    last_name,
    phone)
SELECT
    DISTINCT
    SPLIT_PART(raw_data.sales.person_name, ' ', 1),
    SPLIT_PART(raw_data.sales.person_name, ' ', 2),
    REPLACE(raw_data.sales.phone, '.', '-')
FROM raw_data.sales
WHERE NOT (raw_data.sales.person_name
LIKE ANY (array['Mrs.%', 'Miss%', 'Mrs.%', 'Mr.%', 'Dr.%', '%Jr.', '%MD', '%DDS', '%MD', '%DVM', '%II']));

-- Заполняем таблицу клиентами у которых есть аббревиатуры Jr. MD. И т.д.
INSERT INTO car_shop.clients(
    first_name,
    last_name,
    phone,
    abbreviation)
SELECT
    DISTINCT
    SPLIT_PART(raw_data.sales.person_name, ' ', 1),
    SPLIT_PART(raw_data.sales.person_name, ' ', 2),
    REPLACE(raw_data.sales.phone, '.', '-'),
    SPLIT_PART(raw_data.sales.person_name, ' ', -1)
FROM raw_data.sales
WHERE NOT (raw_data.sales.person_name
LIKE ANY (array['Mrs.%', 'Miss%', 'Mrs.%', 'Mr.%', 'Dr.%']))
AND (raw_data.sales.person_name
LIKE ANY (array['%Jr.', '%MD', '%DDS', '%MD', '%DVM', '%II']));

-- Заполняем таблицу клиентами у которых есть обращения Mrs. Miss. И т.д.
INSERT INTO car_shop.clients(
    first_name,
    last_name,
    phone,
    title)
SELECT
    DISTINCT
    SPLIT_PART(raw_data.sales.person_name, ' ', 2),
    SPLIT_PART(raw_data.sales.person_name, ' ', 3),
    REPLACE(raw_data.sales.phone, '.', '-'),
    SPLIT_PART(raw_data.sales.person_name, ' ', 1)
FROM raw_data.sales
WHERE NOT (raw_data.sales.person_name
LIKE ANY (array['%Jr.', '%MD', '%DDS', '%MD', '%DVM', '%II']))
AND (raw_data.sales.person_name
LIKE ANY (array['Mrs.%', 'Miss%', 'Mrs.%', 'Mr.%', 'Dr.%']));

-- Заполняем таблицу клиентами у которых есть и обращения и аббревиатуры.
INSERT INTO car_shop.clients(
    first_name,
    last_name,
    phone,
    abbreviation,
    title)
SELECT
    DISTINCT
    SPLIT_PART(raw_data.sales.person_name, ' ', 2),
    SPLIT_PART(raw_data.sales.person_name, ' ', 3),
    REPLACE(raw_data.sales.phone, '.', '-'),
    SPLIT_PART(raw_data.sales.person_name, ' ', -1),
    SPLIT_PART(raw_data.sales.person_name, ' ', 1)
FROM raw_data.sales
WHERE (raw_data.sales.person_name
LIKE ANY (array['Mrs.%', 'Miss%', 'Mrs.%', 'Mr.%', 'Dr.%']))
AND (raw_data.sales.person_name
LIKE ANY (array['%Jr.', '%MD', '%DDS', '%MD', '%DVM', '%II']));

-- Заполняем таблицу продаж данными.
INSERT INTO car_shop.sales(
    date,
    price,
    discount,
    car_id,
    client_id)
SELECT
    date,
    price,
    discount,
    car_shop.cars.id,
    car_shop.clients.id
FROM car_shop.cars
LEFT JOIN car_shop.car_colors ON car_shop.cars.color_id = car_shop.car_colors.id
LEFT JOIN (car_shop.car_models
    LEFT JOIN car_shop.car_brands ON car_shop.car_brands.id = car_shop.car_models.brand_id)
    ON car_shop.car_models.id = car_shop.cars.model_id
RIGHT JOIN raw_data.sales
    ON (raw_data.sales.auto = (
        SELECT TRIM(CONCAT(car_shop.car_brands.brand, '', car_shop.car_models.model, ',', car_shop.car_colors.color))))
LEFT JOIN car_shop.clients ON raw_data.sales.person_name = (
SELECT TRIM(CONCAT(
    car_shop.clients.title, ' ',
    car_shop.clients.first_name, ' ',
    car_shop.clients.last_name, ' ',
    car_shop.clients.abbreviation)));
