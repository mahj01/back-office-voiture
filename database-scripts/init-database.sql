-- ============================================================
-- SCRIPT D'INITIALISATION DE LA BASE DE DONNEES (DEV)
-- Projet: Voiture Reservation - Back Office
-- ============================================================
-- Usage: psql -U postgres -f init-database.sql
-- ============================================================

-- 1) CREATION DE LA BASE DE DONNEES
DROP DATABASE IF EXISTS voiture_reservation;
CREATE DATABASE voiture_reservation;

\c voiture_reservation;

-- 2) CREATION DU SCHEMA DEV
CREATE SCHEMA IF NOT EXISTS dev;

-- 3) CREATION DU ROLE app_dev
DROP ROLE IF EXISTS app_dev;
CREATE ROLE app_dev LOGIN PASSWORD 'dev_pwd';
GRANT USAGE, CREATE ON SCHEMA dev TO app_dev;
ALTER ROLE app_dev SET search_path = dev;

-- 4) CREATION DES TABLES
SET search_path = dev;

BEGIN;

DROP TABLE IF EXISTS reservation CASCADE;
DROP TABLE IF EXISTS distance CASCADE;
DROP TABLE IF EXISTS voiture CASCADE;
DROP TABLE IF EXISTS lieu CASCADE;
DROP TABLE IF EXISTS type_lieu CASCADE;
DROP TABLE IF EXISTS parametre CASCADE;
DROP TABLE IF EXISTS token CASCADE;

-- Table type_lieu
CREATE TABLE type_lieu (
    id SERIAL PRIMARY KEY,
    libelle VARCHAR(255) NOT NULL UNIQUE
);

-- Table lieu
CREATE TABLE lieu (
    id SERIAL PRIMARY KEY,
    code VARCHAR(255) NOT NULL UNIQUE,
    libelle VARCHAR(255) NOT NULL,
    type_lieu INTEGER NOT NULL,
    CONSTRAINT fk_lieu_type_lieu
        FOREIGN KEY (type_lieu) REFERENCES type_lieu(id)
);

-- Table voiture
CREATE TABLE voiture (
    id SERIAL PRIMARY KEY,
    matricule VARCHAR(50) NOT NULL UNIQUE,
    marque VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    nombre_place INTEGER NOT NULL CHECK (nombre_place > 0),
    type_carburant VARCHAR(2) NOT NULL,
    vitesse_moyenne DECIMAL(10,2),
    temp_attente DECIMAL(10,2),
    depart_heure_disponibilite TIMESTAMP
);

-- Table reservation
CREATE TABLE reservation (
    id SERIAL PRIMARY KEY,
    idClient INTEGER NOT NULL,
    idLieu INTEGER NOT NULL,
    dateArrivee TIMESTAMP NOT NULL,
    nombrePassagers INTEGER NOT NULL CHECK (nombrePassagers > 0),
    idLieuAtterissage INTEGER,
    CONSTRAINT fk_reservation_lieu_destination
        FOREIGN KEY (idLieu) REFERENCES lieu(id),
    CONSTRAINT fk_reservation_lieu_atterissage
        FOREIGN KEY (idLieuAtterissage) REFERENCES lieu(id)
);

-- Table distance
CREATE TABLE distance (
    id SERIAL PRIMARY KEY,
    lieu_from INTEGER NOT NULL,
    lieu_to INTEGER NOT NULL,
    km DOUBLE PRECISION NOT NULL CHECK (km >= 0),
    CONSTRAINT fk_distance_lieu_from
        FOREIGN KEY (lieu_from) REFERENCES lieu(id) ON DELETE CASCADE,
    CONSTRAINT fk_distance_lieu_to
        FOREIGN KEY (lieu_to) REFERENCES lieu(id) ON DELETE CASCADE,
    CONSTRAINT ck_distance_lieux_differents CHECK (lieu_from <> lieu_to),
    CONSTRAINT uq_distance_sens UNIQUE (lieu_from, lieu_to)
);

-- Table parametre
CREATE TABLE parametre (
    id SERIAL PRIMARY KEY,
    libelle VARCHAR(255) NOT NULL UNIQUE,
    valeur VARCHAR(255) NOT NULL
);

-- Table token
CREATE TABLE token (
    id SERIAL PRIMARY KEY,
    token VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP NOT NULL
);

COMMIT;

-- 5) DROITS SUR LES TABLES
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA dev TO app_dev;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA dev TO app_dev;

-- 6) DONNEES DE REFERENCE
INSERT INTO type_lieu (libelle) VALUES ('AEROPORT'), ('HOTEL');

INSERT INTO parametre (libelle, valeur) VALUES ('TA', '30'), ('vitesse', '30');

-- 7) VERIFICATION
SELECT '=== TABLES CREEES ===' AS info;
SELECT 'type_lieu' AS table_name, COUNT(*) AS nb_rows FROM dev.type_lieu
UNION ALL SELECT 'lieu', COUNT(*) FROM dev.lieu
UNION ALL SELECT 'voiture', COUNT(*) FROM dev.voiture
UNION ALL SELECT 'reservation', COUNT(*) FROM dev.reservation
UNION ALL SELECT 'distance', COUNT(*) FROM dev.distance
UNION ALL SELECT 'parametre', COUNT(*) FROM dev.parametre
UNION ALL SELECT 'token', COUNT(*) FROM dev.token;

SELECT '=== INITIALISATION TERMINEE ===' AS message;
