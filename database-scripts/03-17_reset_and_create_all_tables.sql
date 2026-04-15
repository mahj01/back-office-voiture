-- ============================================================
-- RESET COMPLET + STRUCTURE FINALE DES TABLES (etat actuel app)
-- ============================================================
-- Usage:
-- psql -h localhost -U app_dev -d voiture_reservation -f database-scripts/03-17_reset_and_create_all_tables.sql

BEGIN;

-- 1) Suppression complete des tables (donnees + structure)
DROP TABLE IF EXISTS reservation CASCADE;
DROP TABLE IF EXISTS distance CASCADE;
DROP TABLE IF EXISTS voiture CASCADE;
DROP TABLE IF EXISTS lieu CASCADE;
DROP TABLE IF EXISTS type_lieu CASCADE;
DROP TABLE IF EXISTS parametre CASCADE;
DROP TABLE IF EXISTS token CASCADE;

-- 2) Recreation des tables
CREATE TABLE type_lieu (
    id SERIAL PRIMARY KEY,
    libelle VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE lieu (
    id SERIAL PRIMARY KEY,
    code VARCHAR(255) NOT NULL UNIQUE,
    libelle VARCHAR(255) NOT NULL,
    type_lieu INTEGER NOT NULL,
    CONSTRAINT fk_lieu_type_lieu
        FOREIGN KEY (type_lieu) REFERENCES type_lieu(id)
);

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

CREATE TABLE parametre (
    id SERIAL PRIMARY KEY,
    libelle VARCHAR(255) NOT NULL UNIQUE,
    valeur VARCHAR(255) NOT NULL
);

CREATE TABLE token (
    id SERIAL PRIMARY KEY,
    token VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP NOT NULL
);

-- 3) Donnees minimales de reference
INSERT INTO type_lieu (libelle) VALUES
('AEROPORT'),
('HOTEL')
ON CONFLICT (libelle) DO NOTHING;

INSERT INTO parametre (libelle, valeur) VALUES
('TA', '30'),
('vitesse', '30')
ON CONFLICT (libelle) DO UPDATE SET valeur = EXCLUDED.valeur;

COMMIT;

-- 4) Verification rapide
SELECT 'type_lieu' AS table_name, COUNT(*) AS nb_rows FROM type_lieu
UNION ALL
SELECT 'lieu', COUNT(*) FROM lieu
UNION ALL
SELECT 'voiture', COUNT(*) FROM voiture
UNION ALL
SELECT 'reservation', COUNT(*) FROM reservation
UNION ALL
SELECT 'distance', COUNT(*) FROM distance
UNION ALL
SELECT 'parametre', COUNT(*) FROM parametre
UNION ALL
SELECT 'token', COUNT(*) FROM token;
