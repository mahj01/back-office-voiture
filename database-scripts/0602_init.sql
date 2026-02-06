CREATE DATABASE voiture_reservation;

\c voiture_reservation;
CREATE SCHEMA dev;
CREATE SCHEMA staging;
CREATE SCHEMA prod;

CREATE ROLE app_dev LOGIN PASSWORD 'dev_pwd';
CREATE ROLE app_staging LOGIN PASSWORD 'staging_pwd';
CREATE ROLE app_prod LOGIN PASSWORD 'prod_pwd';

-- DEV
GRANT USAGE, CREATE ON SCHEMA dev TO app_dev;
GRANT USAGE, CREATE ON SCHEMA staging TO app_dev;
GRANT USAGE, CREATE ON SCHEMA prod TO app_dev;

-- STAGING
GRANT USAGE, CREATE ON SCHEMA staging TO app_staging;
GRANT USAGE, CREATE ON SCHEMA prod TO app_staging;
GRANT USAGE, CREATE ON SCHEMA dev TO app_staging;

-- PROD
GRANT USAGE, CREATE ON SCHEMA prod TO app_prod;
GRANT USAGE, CREATE ON SCHEMA staging TO app_prod;
GRANT USAGE, CREATE ON SCHEMA dev TO app_prod;

ALTER ROLE app_dev SET search_path = dev;
ALTER ROLE app_staging SET search_path = staging;
ALTER ROLE app_prod SET search_path = prod;

psql -U app_dev -d voiture_reservation;

CREATE TABLE hotel(
    id SERIAL PRIMARY KEY,
    nom VARCHAR(255) NOT NULL
);

CREATE TABLE reservation (
    id SERIAL PRIMARY KEY,
    idClient INTEGER NOT NULL,
    idHotel INTEGER NOT NULL REFERENCES hotel(id),
    dateArrivee TIMESTAMP NOT NULL,
    FOREIGN KEY (idHotel) REFERENCES hotel(id)
);

CREATE TABLE staging.hotel (LIKE dev.hotel INCLUDING ALL);
CREATE TABLE prod.hotel (LIKE dev.hotel INCLUDING ALL);
CREATE TABLE staging.reservation (LIKE dev.reservation INCLUDING ALL);
CREATE TABLE prod.reservation (LIKE dev.reservation INCLUDING ALL);
