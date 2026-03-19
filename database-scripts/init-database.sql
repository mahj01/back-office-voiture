-- ============================================================
-- SCRIPT COMPLET D'INITIALISATION DE LA BASE DE DONNEES
-- Projet: Voiture Reservation - Back Office
-- ============================================================
-- Ce script cree:
--   1. La base de donnees
--   2. Les schemas (dev, staging, prod)
--   3. Les roles avec permissions
--   4. Toutes les tables
--   5. Les donnees de reference minimales
-- ============================================================
-- Usage:
--   psql -U postgres -f init-database.sql
-- ============================================================

-- ============================================================
-- 1) CREATION DE LA BASE DE DONNEES
-- ============================================================

-- Supprimer la base si elle existe (attention: perte de donnees)
DROP DATABASE IF EXISTS voiture_reservation;

-- Creer la base de donnees
CREATE DATABASE voiture_reservation;

-- Se connecter a la nouvelle base
\c voiture_reservation;

-- ============================================================
-- 2) CREATION DES SCHEMAS
-- ============================================================

CREATE SCHEMA IF NOT EXISTS dev;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS prod;

-- ============================================================
-- 3) CREATION DES ROLES ET PERMISSIONS
-- ============================================================

-- Supprimer les roles s'ils existent (ignorer les erreurs)
DROP ROLE IF EXISTS app_dev;
DROP ROLE IF EXISTS app_staging;
DROP ROLE IF EXISTS app_prod;

-- Creer les roles
CREATE ROLE app_dev LOGIN PASSWORD 'dev_pwd';
CREATE ROLE app_staging LOGIN PASSWORD 'staging_pwd';
CREATE ROLE app_prod LOGIN PASSWORD 'prod_pwd';

-- Permissions DEV
GRANT USAGE, CREATE ON SCHEMA dev TO app_dev;
GRANT USAGE, CREATE ON SCHEMA staging TO app_dev;
GRANT USAGE, CREATE ON SCHEMA prod TO app_dev;

-- Permissions STAGING
GRANT USAGE, CREATE ON SCHEMA staging TO app_staging;
GRANT USAGE, CREATE ON SCHEMA prod TO app_staging;
GRANT USAGE, CREATE ON SCHEMA dev TO app_staging;

-- Permissions PROD
GRANT USAGE, CREATE ON SCHEMA prod TO app_prod;
GRANT USAGE, CREATE ON SCHEMA staging TO app_prod;
GRANT USAGE, CREATE ON SCHEMA dev TO app_prod;

-- Definir le search_path par defaut pour chaque role
ALTER ROLE app_dev SET search_path = dev;
ALTER ROLE app_staging SET search_path = staging;
ALTER ROLE app_prod SET search_path = prod;

-- ============================================================
-- 4) CREATION DES TABLES (SCHEMA DEV)
-- ============================================================

SET search_path = dev;

BEGIN;

-- Suppression des tables existantes
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
    temp_attente DECIMAL(10,2)
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

-- ============================================================
-- 5) DONNER LES DROITS SUR LES TABLES AU ROLE app_dev
-- ============================================================

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA dev TO app_dev;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA dev TO app_dev;

-- ============================================================
-- 6) CREATION DES TABLES DANS LES AUTRES SCHEMAS
-- ============================================================

-- Schema STAGING
CREATE TABLE staging.type_lieu (LIKE dev.type_lieu INCLUDING ALL);
CREATE TABLE staging.lieu (LIKE dev.lieu INCLUDING ALL);
CREATE TABLE staging.voiture (LIKE dev.voiture INCLUDING ALL);
CREATE TABLE staging.reservation (LIKE dev.reservation INCLUDING ALL);
CREATE TABLE staging.distance (LIKE dev.distance INCLUDING ALL);
CREATE TABLE staging.parametre (LIKE dev.parametre INCLUDING ALL);
CREATE TABLE staging.token (LIKE dev.token INCLUDING ALL);

-- Ajouter les contraintes FK pour staging
ALTER TABLE staging.lieu ADD CONSTRAINT fk_lieu_type_lieu
    FOREIGN KEY (type_lieu) REFERENCES staging.type_lieu(id);
ALTER TABLE staging.reservation ADD CONSTRAINT fk_reservation_lieu_destination
    FOREIGN KEY (idLieu) REFERENCES staging.lieu(id);
ALTER TABLE staging.reservation ADD CONSTRAINT fk_reservation_lieu_atterissage
    FOREIGN KEY (idLieuAtterissage) REFERENCES staging.lieu(id);
ALTER TABLE staging.distance ADD CONSTRAINT fk_distance_lieu_from
    FOREIGN KEY (lieu_from) REFERENCES staging.lieu(id) ON DELETE CASCADE;
ALTER TABLE staging.distance ADD CONSTRAINT fk_distance_lieu_to
    FOREIGN KEY (lieu_to) REFERENCES staging.lieu(id) ON DELETE CASCADE;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA staging TO app_staging;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA staging TO app_staging;

-- Schema PROD
CREATE TABLE prod.type_lieu (LIKE dev.type_lieu INCLUDING ALL);
CREATE TABLE prod.lieu (LIKE dev.lieu INCLUDING ALL);
CREATE TABLE prod.voiture (LIKE dev.voiture INCLUDING ALL);
CREATE TABLE prod.reservation (LIKE dev.reservation INCLUDING ALL);
CREATE TABLE prod.distance (LIKE dev.distance INCLUDING ALL);
CREATE TABLE prod.parametre (LIKE dev.parametre INCLUDING ALL);
CREATE TABLE prod.token (LIKE dev.token INCLUDING ALL);

-- Ajouter les contraintes FK pour prod
ALTER TABLE prod.lieu ADD CONSTRAINT fk_lieu_type_lieu
    FOREIGN KEY (type_lieu) REFERENCES prod.type_lieu(id);
ALTER TABLE prod.reservation ADD CONSTRAINT fk_reservation_lieu_destination
    FOREIGN KEY (idLieu) REFERENCES prod.lieu(id);
ALTER TABLE prod.reservation ADD CONSTRAINT fk_reservation_lieu_atterissage
    FOREIGN KEY (idLieuAtterissage) REFERENCES prod.lieu(id);
ALTER TABLE prod.distance ADD CONSTRAINT fk_distance_lieu_from
    FOREIGN KEY (lieu_from) REFERENCES prod.lieu(id) ON DELETE CASCADE;
ALTER TABLE prod.distance ADD CONSTRAINT fk_distance_lieu_to
    FOREIGN KEY (lieu_to) REFERENCES prod.lieu(id) ON DELETE CASCADE;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA prod TO app_prod;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA prod TO app_prod;

-- ============================================================
-- 7) DONNEES DE REFERENCE MINIMALES (SCHEMA DEV)
-- ============================================================

SET search_path = dev;

-- Types de lieu
INSERT INTO type_lieu (libelle) VALUES
('AEROPORT'),
('HOTEL')
ON CONFLICT (libelle) DO NOTHING;

-- Parametres
INSERT INTO parametre (libelle, valeur) VALUES
('TA', '30'),
('vitesse', '30')
ON CONFLICT (libelle) DO UPDATE SET valeur = EXCLUDED.valeur;

-- ============================================================
-- 8) VERIFICATION FINALE
-- ============================================================

SELECT '=== TABLES CREEES DANS LE SCHEMA DEV ===' AS info;

SELECT 'type_lieu' AS table_name, COUNT(*) AS nb_rows FROM dev.type_lieu
UNION ALL
SELECT 'lieu', COUNT(*) FROM dev.lieu
UNION ALL
SELECT 'voiture', COUNT(*) FROM dev.voiture
UNION ALL
SELECT 'reservation', COUNT(*) FROM dev.reservation
UNION ALL
SELECT 'distance', COUNT(*) FROM dev.distance
UNION ALL
SELECT 'parametre', COUNT(*) FROM dev.parametre
UNION ALL
SELECT 'token', COUNT(*) FROM dev.token;

SELECT '=== SCHEMAS DISPONIBLES ===' AS info;
SELECT schema_name FROM information_schema.schemata
WHERE schema_name IN ('dev', 'staging', 'prod');

SELECT '=== ROLES CREES ===' AS info;
SELECT rolname FROM pg_roles WHERE rolname LIKE 'app_%';

SELECT '=== INITIALISATION TERMINEE ===' AS message;
