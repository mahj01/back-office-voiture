-- ============================================================
-- Chargement des donnees de test depuis data.csv
-- Cible: schema dev (voir init-database.sql)
-- ============================================================
-- Usage:
-- psql -h localhost -U app_dev -d voiture_reservation -f database-scripts/03-19_load_data_from_csv.sql

SET search_path = dev;

BEGIN;


-- 1) Nettoyage des donnees existantes
TRUNCATE TABLE reservation, distance, voiture, lieu, parametre, type_lieu RESTART IDENTITY CASCADE;

-- 2) Types de lieux (requis pour la table lieu)
INSERT INTO type_lieu (libelle) VALUES
('AEROPORT'),
('HOTEL');

-- 3) Parametres (conversion de la section PARAMETRE du CSV)
-- CSV: temps_attente=30, vitesse_moyenne=50
INSERT INTO parametre (libelle, valeur) VALUES
('TA', '30'),
('vitesse', '50');

-- 4) Lieux (conversion des noms du CSV)
INSERT INTO lieu (code, libelle, type_lieu) VALUES
('AIR01', 'aeroport', 1),
('HOT01', 'hotel1',   2),
('HOT02', 'hotel2',   2);

-- 5) Voitures
-- depart_heure_dispo du CSV est une heure seule: on la convertit en TIMESTAMP sur la date de test 2026-03-19
INSERT INTO voiture (matricule, marque, model, nombre_place, type_carburant, vitesse_moyenne, temp_attente, depart_heure_disponibilite) VALUES
('vehicule1', 'Marque1', 'Model1',  5, 'D', 50.00, 5.00, TIMESTAMP '2026-03-19 00:00:00'),
('vehicule2', 'Marque2', 'Model2',  5, 'E', 50.00, 5.00, TIMESTAMP '2026-03-19 00:00:00'),
('vehicule3', 'Marque3', 'Model3', 12, 'D', 50.00, 5.00, TIMESTAMP '2026-03-19 00:00:00'),
('vehicule4', 'Marque4', 'Model4',  9, 'D', 50.00, 5.00, TIMESTAMP '2026-03-19 00:00:00'),
('vehicule5', 'Marque5', 'Model5', 12, 'E', 50.00, 5.00, TIMESTAMP '2026-03-19 13:00:00');

-- 6) Distances
-- Remarque: dans data.csv, la ligne id=2 duplique aeroport->hotel1 (contrainte uq_distance_sens interdit le doublon).
-- On l'interprete comme aeroport->hotel2 pour conserver 3 trajets distincts.
INSERT INTO distance (lieu_from, lieu_to, km) VALUES
((SELECT id FROM lieu WHERE code = 'AIR01'), (SELECT id FROM lieu WHERE code = 'HOT01'), 90),
((SELECT id FROM lieu WHERE code = 'AIR01'), (SELECT id FROM lieu WHERE code = 'HOT02'), 35),
((SELECT id FROM lieu WHERE code = 'HOT01'), (SELECT id FROM lieu WHERE code = 'HOT02'), 60);

-- 7) Reservations
-- idClient: conversion ClientN -> N
-- date+heure CSV converties en TIMESTAMP
-- idLieuAtterissage: aeroport (AIR01)
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage) VALUES
(1, (SELECT id FROM lieu WHERE code = 'HOT01'), TIMESTAMP '2026-03-19 09:00:00',  7, (SELECT id FROM lieu WHERE code = 'AIR01')),
(2, (SELECT id FROM lieu WHERE code = 'HOT02'), TIMESTAMP '2026-03-19 08:00:00', 20, (SELECT id FROM lieu WHERE code = 'AIR01')),
(3, (SELECT id FROM lieu WHERE code = 'HOT01'), TIMESTAMP '2026-03-19 09:10:00',  3, (SELECT id FROM lieu WHERE code = 'AIR01')),
(4, (SELECT id FROM lieu WHERE code = 'HOT01'), TIMESTAMP '2026-03-19 09:15:00', 10, (SELECT id FROM lieu WHERE code = 'AIR01')),
(5, (SELECT id FROM lieu WHERE code = 'HOT01'), TIMESTAMP '2026-03-19 09:20:00',  5, (SELECT id FROM lieu WHERE code = 'AIR01')),
(6, (SELECT id FROM lieu WHERE code = 'HOT01'), TIMESTAMP '2026-03-19 13:30:00', 12, (SELECT id FROM lieu WHERE code = 'AIR01'));

COMMIT;


-- 8) Verification rapide
SELECT 'voiture' AS table_name, COUNT(*) AS nb_rows FROM voiture
UNION ALL SELECT 'reservation', COUNT(*) FROM reservation
UNION ALL SELECT 'distance', COUNT(*) FROM distance
UNION ALL SELECT 'lieu', COUNT(*) FROM lieu
UNION ALL SELECT 'parametre', COUNT(*) FROM parametre;
