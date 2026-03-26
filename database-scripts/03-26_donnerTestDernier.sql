-- ============================================================
-- SCRIPT DE TEST : Scenario depuis image (19/03/2026)
-- ============================================================
-- Usage:
-- psql -h localhost -U app_dev -d voiture_reservation -f database-scripts/03-26_test_scenario_image.sql

BEGIN;

-- 0) Reinitialisation des donnees de test
TRUNCATE TABLE reservation, distance, lieu, type_lieu, voiture, parametre, token
    RESTART IDENTITY CASCADE;

-- 1) Types de lieu
INSERT INTO type_lieu (libelle) VALUES ('AEROPORT');
INSERT INTO type_lieu (libelle) VALUES ('HOTEL');

-- 2) Lieux
INSERT INTO lieu (code, libelle, type_lieu) VALUES
('AIR',  'aeroport', (SELECT id FROM type_lieu WHERE libelle = 'AEROPORT')),
('HOT1', 'hotel1',   (SELECT id FROM type_lieu WHERE libelle = 'HOTEL')),
('HOT2', 'hotel2',   (SELECT id FROM type_lieu WHERE libelle = 'HOTEL'));

-- 3) Distances (d'apres l'image)
INSERT INTO distance (lieu_from, lieu_to, km)
SELECT lf.id, lt.id, 90
FROM lieu lf, lieu lt
WHERE lf.code = 'AIR' AND lt.code = 'HOT1';

INSERT INTO distance (lieu_from, lieu_to, km)
SELECT lf.id, lt.id, 35
FROM lieu lf, lieu lt
WHERE lf.code = 'AIR' AND lt.code = 'HOT2';

INSERT INTO distance (lieu_from, lieu_to, km)
SELECT lf.id, lt.id, 60
FROM lieu lf, lieu lt
WHERE lf.code = 'HOT1' AND lt.code = 'HOT2';

-- 4) Parametres
INSERT INTO parametre (libelle, valeur) VALUES
('temps_attente', '30'),
('vitesse', '50');

-- 5) Voitures
-- Mapping type image -> type_carburant:
-- diesel => D, essence => E
INSERT INTO voiture (
    matricule,
    marque,
    model,
    nombre_place,
    type_carburant,
    depart_heure_disponibilite
) VALUES
('vehicule1', 'N/A', 'N/A', 5,  'D', '2026-03-19 09:00:00'),
('vehicule2', 'N/A', 'N/A', 5,  'E', '2026-03-19 09:00:00'),
('vehicule3', 'N/A', 'N/A', 12, 'D', '2026-03-19 00:00:00'),
('vehicule4', 'N/A', 'N/A', 9,  'D', '2026-03-19 09:00:00'),
('vehicule5', 'N/A', 'N/A', 12, 'E', '2026-03-19 13:00:00');

-- 6) Reservations (date image: 19/03/26)
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES
(1, (SELECT id FROM lieu WHERE code = 'HOT1'), '2026-03-19 09:00:00', 7,  (SELECT id FROM lieu WHERE code = 'AIR')),
(2, (SELECT id FROM lieu WHERE code = 'HOT2'), '2026-03-19 08:00:00', 20, (SELECT id FROM lieu WHERE code = 'AIR')),
(3, (SELECT id FROM lieu WHERE code = 'HOT1'), '2026-03-19 09:10:00', 3,  (SELECT id FROM lieu WHERE code = 'AIR')),
(4, (SELECT id FROM lieu WHERE code = 'HOT1'), '2026-03-19 09:15:00', 10, (SELECT id FROM lieu WHERE code = 'AIR')),
(5, (SELECT id FROM lieu WHERE code = 'HOT1'), '2026-03-19 09:20:00', 5,  (SELECT id FROM lieu WHERE code = 'AIR')),
(6, (SELECT id FROM lieu WHERE code = 'HOT1'), '2026-03-19 13:30:00', 12, (SELECT id FROM lieu WHERE code = 'AIR'));

COMMIT;

-- 7) Verification rapide
SELECT '=== PARAMETRES ===' AS info;
SELECT * FROM parametre ORDER BY id;

SELECT '=== LIEUX ===' AS info;
SELECT id, code, libelle FROM lieu ORDER BY id;

SELECT '=== VOITURES ===' AS info;
SELECT matricule, nombre_place, type_carburant, depart_heure_disponibilite
FROM voiture
ORDER BY id;

SELECT '=== DISTANCES ===' AS info;
SELECT lf.code AS de, lt.code AS vers, d.km
FROM distance d
JOIN lieu lf ON d.lieu_from = lf.id
JOIN lieu lt ON d.lieu_to = lt.id
ORDER BY d.id;

SELECT '=== RESERVATIONS ===' AS info;
SELECT r.id, r.idclient, l.code AS destination, r.nombrepassagers,
       TO_CHAR(r.datearrivee, 'YYYY-MM-DD HH24:MI:SS') AS date_heure
FROM reservation r
JOIN lieu l ON r.idlieu = l.id
ORDER BY r.datearrivee;
