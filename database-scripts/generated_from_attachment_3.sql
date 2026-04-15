-- Script généré (variante 3) à partir de la capture fournie
-- Scénario: 25/03/2026, 6 réservations vers Hotel1, distance 50 km, TA=30, vitesse=50, 2 véhicules
-- Schéma : dev (voir init-database.sql)

SET search_path = dev;

BEGIN;

-- Réinitialisation (optionnel)
TRUNCATE TABLE reservation, distance, lieu, type_lieu, voiture, parametre, token RESTART IDENTITY CASCADE;

-- Types et lieux
INSERT INTO type_lieu (libelle) VALUES ('AEROPORT') ON CONFLICT DO NOTHING;
INSERT INTO type_lieu (libelle) VALUES ('HOTEL') ON CONFLICT DO NOTHING;

INSERT INTO lieu (code, libelle, type_lieu)
VALUES
('AIR', 'Aeroport Principal', (SELECT id FROM type_lieu WHERE libelle='AEROPORT')),
('HOT1', 'Hotel1', (SELECT id FROM type_lieu WHERE libelle='HOTEL'))
ON CONFLICT DO NOTHING;

-- Distance Aéroport -> Hotel1 = 50 km
INSERT INTO distance (lieu_from, lieu_to, km)
SELECT a.id, b.id, 50.00
FROM lieu a, lieu b
WHERE a.code = 'AIR' AND b.code = 'HOT1'
ON CONFLICT (lieu_from, lieu_to) DO NOTHING;

-- Paramètres
INSERT INTO parametre (libelle, valeur) VALUES ('TA', '30') ON CONFLICT DO NOTHING;
INSERT INTO parametre (libelle, valeur) VALUES ('vitesse', '50') ON CONFLICT DO NOTHING;

-- Véhicules observés (Vehicle1: 12 places, Vehicle2: 13 places)
INSERT INTO voiture (matricule, marque, model, nombre_place, type_carburant, vitesse_moyenne, temp_attente, depart_heure_disponibilite)
VALUES
('VEHICLE1', 'Generic', 'Van12', 12, 'D', 50.00, 30.00, '2026-03-25 00:00:00'),
('VEHICLE2', 'Generic', 'Van13', 13, 'D', 50.00, 30.00, '2026-03-25 00:00:00')
ON CONFLICT DO NOTHING;

-- Réservations (25/03/2026)
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES
(3001, (SELECT id FROM lieu WHERE code='HOT1'), '2026-03-25 08:00:00', 10, (SELECT id FROM lieu WHERE code='AIR')),
(3002, (SELECT id FROM lieu WHERE code='HOT1'), '2026-03-25 08:10:00', 15, (SELECT id FROM lieu WHERE code='AIR')),
(3003, (SELECT id FROM lieu WHERE code='HOT1'), '2026-03-25 08:15:00', 8,  (SELECT id FROM lieu WHERE code='AIR')),
(3004, (SELECT id FROM lieu WHERE code='HOT1'), '2026-03-25 10:45:00', 5,  (SELECT id FROM lieu WHERE code='AIR')),
(3005, (SELECT id FROM lieu WHERE code='HOT1'), '2026-03-25 11:00:00', 13, (SELECT id FROM lieu WHERE code='AIR')),
(3006, (SELECT id FROM lieu WHERE code='HOT1'), '2026-03-25 11:00:00', 13, (SELECT id FROM lieu WHERE code='AIR'));

COMMIT;

-- Vérification rapide
SELECT 'DONE: inserted variant 3 sample data' AS info;
SELECT * FROM voiture ORDER BY id;
SELECT id, idclient, nombrepassagers, TO_CHAR(datearrivee, 'YYYY-MM-DD HH24:MI') AS when FROM reservation ORDER BY datearrivee;
