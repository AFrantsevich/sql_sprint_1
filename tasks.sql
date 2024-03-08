-- TASK 1
SELECT ROUND(CAST(COUNT(*) * 100 / (SELECT COUNT(*) FROM car_shop.car_models) AS numeric), 2)
    AS nulls_percentage_gasoline_consumption
FROM car_shop.car_models
WHERE gasoline_consumption IS NULL;

-- TASK 2
SELECT
    car_shop.car_brands.brand,
    ROUND(AVG(sales.price), 2),
    EXTRACT(YEAR FROM sales.date) AS sd
FROM car_shop.sales
LEFT JOIN car_shop.cars ON car_shop.cars.id = car_shop.sales.car_id
LEFT JOIN car_shop.car_models ON car_shop.cars.model_id = car_shop.car_models.id
LEFT JOIN car_shop.car_brands ON car_shop.car_models.brand_id = car_shop.car_brands.id
GROUP BY
    car_shop.car_brands.brand,
    EXTRACT(YEAR FROM sales.date)
ORDER BY car_shop.car_brands.brand, sd;

-- TASK 3
SELECT
    EXTRACT(MONTH FROM sales.date) AS month,
    EXTRACT(YEAR FROM sales.date) AS year,
    ROUND(AVG(sales.price), 2)
FROM car_shop.sales
WHERE EXTRACT(YEAR FROM sales.date) = 2022
GROUP BY
    EXTRACT(MONTH FROM sales.date),
    EXTRACT(YEAR FROM sales.date)
ORDER BY month;

-- TASK 4
SELECT TRIM(CONCAT(
    car_shop.clients.title, ' ',
    car_shop.clients.first_name, ' ',
    car_shop.clients.last_name, ' ',
    car_shop.clients.abbreviation)) AS person,
    STRING_AGG(CONCAT(car_shop.car_brands.brand, '', car_shop.car_models.model), ', ') AS cars
FROM car_shop.clients
RIGHT JOIN car_shop.sales ON car_shop.sales.client_id = car_shop.clients.id
LEFT JOIN car_shop.cars ON car_shop.cars.id = car_shop.sales.car_id
LEFT JOIN car_shop.car_models ON car_shop.cars.model_id = car_shop.car_models.id
LEFT JOIN car_shop.car_brands ON car_shop.car_models.brand_id = car_shop.car_brands.id
GROUP BY TRIM(CONCAT(
    car_shop.clients.title, ' ',
    car_shop.clients.first_name, ' ',
    car_shop.clients.last_name, ' ',
    car_shop.clients.abbreviation))
ORDER BY person;

-- TASK 5
SELECT
    car_shop.brand_origins.brand_origin,
    MAX(CASE WHEN sales.discount = 0
        THEN car_shop.sales.price
            ELSE ((car_shop.sales.price*100)/(100-car_shop.sales.discount))::numeric(9, 2)
        END) AS max_price,
    MIN(CASE WHEN sales.discount = 0
        THEN car_shop.sales.price
            ELSE ((car_shop.sales.price*100)/(100-car_shop.sales.discount))::numeric(9, 2)
        END) AS min_price
FROM car_shop.sales
LEFT JOIN car_shop.cars ON car_shop.sales.car_id = car_shop.cars.id
LEFT JOIN car_shop.car_models ON car_shop.car_models.id = car_shop.cars.model_id
LEFT JOIN (car_shop.car_brands
        LEFT JOIN car_shop.brand_origins ON car_shop.brand_origins.id = car_shop.car_brands.brand_origin_id)
    ON car_shop.car_models.brand_id = car_shop.car_brands.id
WHERE car_shop.brand_origins.brand_origin IS NOT NULL
GROUP BY car_shop.brand_origins.brand_origin;

-- TASK 6
SELECT COUNT(*)
FROM car_shop.clients
WHERE car_shop.clients.phone
LIKE '+1%';
