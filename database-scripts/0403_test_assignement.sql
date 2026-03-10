-- Script de test pour l'assignation des réservations aux voitures
-- Date: 2026-03-04
-- Compatible PostgreSQL

-- =====================================================
-- NETTOYAGE DES DONNEES EXISTANTES
-- =====================================================
DELETE FROM reservation;
DELETE FROM voiture;
DELETE FROM lieu;
DELETE FROM type_lieu;

-- Reset sequences (ignorer les erreurs si les séquences n'existent pas)
-- ALTER SEQUENCE type_lieu_id_seq RESTART WITH 1;
-- ALTER SEQUENCE lieu_id_seq RESTART WITH 1;
-- ALTER SEQUENCE voiture_id_seq RESTART WITH 1;
-- ALTER SEQUENCE reservation_id_seq RESTART WITH 1;

-- =====================================================
-- INSERTION DES TYPES DE LIEU
-- =====================================================
INSERT INTO type_lieu (libelle) VALUES ('AEROPORT');
INSERT INTO type_lieu (libelle) VALUES ('HOTEL');

-- =====================================================
-- INSERTION DES LIEUX
-- =====================================================
INSERT INTO lieu (code, libelle, type_lieu) VALUES 
('AIR', 'Aéroport Ivato', (SELECT id FROM type_lieu WHERE libelle = 'AEROPORT')),
('HOT1', 'Hôtel Colbert', (SELECT id FROM type_lieu WHERE libelle = 'HOTEL')),
('HOT2', 'Hôtel Carlton', (SELECT id FROM type_lieu WHERE libelle = 'HOTEL')),
('GAR', 'Gare Soarano', (SELECT id FROM type_lieu WHERE libelle = 'HOTEL'));

-- =====================================================
-- INSERTION DES VOITURES (variées pour tester les règles)
-- =====================================================
-- Voitures 5 places
INSERT INTO voiture (matricule, marque, model, nombre_place, type_carburant) VALUES
('1111AA', 'Toyota', 'Corolla', 5, 'G'),      -- Essence
('2222BB', 'Honda', 'Civic', 5, 'D'),          -- Diesel
('3333CC', 'Ford', 'Focus', 5, 'D');           -- Diesel

-- Voitures 8 places
INSERT INTO voiture (matricule, marque, model, nombre_place, type_carburant) VALUES
('4444DD', 'Toyota', 'HiAce', 8, 'G'),         -- Essence
('5555EE', 'Mercedes', 'Vito', 8, 'D'),        -- Diesel
('6666FF', 'Hyundai', 'H1', 8, 'D');           -- Diesel

-- Voitures 10 places
INSERT INTO voiture (matricule, marque, model, nombre_place, type_carburant) VALUES
('7777GG', 'Toyota', 'Coaster', 10, 'D'),      -- Diesel
('8888HH', 'Ford', 'Transit', 10, 'G');        -- Essence

-- Voitures 15 places
INSERT INTO voiture (matricule, marque, model, nombre_place, type_carburant) VALUES
('9999II', 'Mercedes', 'Sprinter', 15, 'D'),   -- Diesel
('0000JJ', 'Iveco', 'Daily', 15, 'D');         -- Diesel

-- =====================================================
-- INSERTION DES RESERVATIONS POUR TEST
-- Date: 2026-03-05 (demain)
-- =====================================================

-- Reservation 1: 3 passagers -> devrait prendre voiture 5 places diesel (2222BB ou 3333CC)
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers) VALUES
(1, (SELECT id FROM lieu WHERE code = 'AIR'), '2026-03-05 08:00:00', 3);

-- Reservation 2: 5 passagers -> devrait prendre voiture 5 places diesel (priorité)
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers) VALUES
(2, (SELECT id FROM lieu WHERE code = 'HOT1'), '2026-03-05 10:00:00', 5);

-- Reservation 3: 7 passagers -> devrait prendre voiture 8 places diesel (5555EE ou 6666FF)
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers) VALUES
(3, (SELECT id FROM lieu WHERE code = 'HOT2'), '2026-03-05 12:00:00', 7);

-- Reservation 4: 8 passagers -> devrait prendre voiture 8 places diesel
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers) VALUES
(4, (SELECT id FROM lieu WHERE code = 'HOT1'), '2026-03-05 14:00:00', 8);

-- Reservation 5: 9 passagers -> devrait prendre voiture 10 places diesel (7777GG)
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers) VALUES
(5, (SELECT id FROM lieu WHERE code = 'AIR'), '2026-03-05 16:00:00', 9);

-- Reservation 6: 12 passagers -> devrait prendre voiture 15 places diesel
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers) VALUES
(6, (SELECT id FROM lieu WHERE code = 'HOT1'), '2026-03-05 18:00:00', 12);

-- =====================================================
-- RESERVATIONS POUR AUTRE DATE (2026-03-06)
-- =====================================================
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers) VALUES
(7, (SELECT id FROM lieu WHERE code = 'AIR'), '2026-03-06 09:00:00', 4);

INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers) VALUES
(8, (SELECT id FROM lieu WHERE code = 'HOT2'), '2026-03-06 11:00:00', 6);

-- =====================================================
-- VERIFICATION DES DONNEES
-- =====================================================
SELECT 'VOITURES:' as info;
SELECT id, matricule, marque, model, nombre_place, type_carburant FROM voiture ORDER BY nombre_place, type_carburant;

SELECT 'RESERVATIONS 2026-03-05:' as info;
SELECT r.id, r.idClient, r.nombrePassagers, l.libelle as lieu, r.dateArrivee 
FROM reservation r 
JOIN lieu l ON r.idLieu = l.id 
WHERE DATE(r.dateArrivee) = '2026-03-05'
ORDER BY r.dateArrivee;

SELECT 'RESERVATIONS 2026-03-06:' as info;
SELECT r.id, r.idClient, r.nombrePassagers, l.libelle as lieu, r.dateArrivee 
FROM reservation r 
JOIN lieu l ON r.idLieu = l.id 
WHERE DATE(r.dateArrivee) = '2026-03-06'
ORDER BY r.dateArrivee;
