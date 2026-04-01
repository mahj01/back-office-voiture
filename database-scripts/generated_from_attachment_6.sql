-- Script généré (variante 4) à partir de la petite capture fournie
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

-- Distance observée : 50 km (Aéroport -> Hotel1)
INSERT INTO distance (lieu_from, lieu_to, km)
SELECT a.id, b.id, 50.00
FROM lieu a, lieu b
WHERE a.code = 'AIR' AND b.code = 'HOT1'
ON CONFLICT (lieu_from, lieu_to) DO NOTHING;

-- Paramètres (temps attente en minutes, vitesse en km/h)
INSERT INTO parametre (libelle, valeur) VALUES ('TA', '30') ON CONFLICT DO NOTHING;
INSERT INTO parametre (libelle, valeur) VALUES ('vitesse', '50') ON CONFLICT DO NOTHING;

-- Véhicule unique observé dans la capture
INSERT INTO voiture (matricule, marque, model, nombre_place, type_carburant, vitesse_moyenne, temp_attente, depart_heure_disponibilite)
VALUES
('VEHICLE1', 'Generic', 'Van10', 9, 'D', 50.00, 30.00, '2026-03-25 10:00:00')
ON CONFLICT DO NOTHING;

INSERT INTO voiture (matricule, marque, model, nombre_place, type_carburant, vitesse_moyenne, temp_attente, depart_heure_disponibilite)
VALUES
    ('VEHICLE2', 'Generic', 'Van10', 7, 'D', 50.00, 30.00, '2026-03-25 10:00:00')
ON CONFLICT DO NOTHING;

-- Réservations (date 25/03/2026, heures et tailles selon la capture)
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES
(2001, (SELECT id FROM lieu WHERE code='HOT1'), '2026-03-25 08:00:00', 3, (SELECT id FROM lieu WHERE code='AIR')),
(2002, (SELECT id FROM lieu WHERE code='HOT1'), '2026-03-25 09:00:00', 7, (SELECT id FROM lieu WHERE code='AIR')),
(2003, (SELECT id FROM lieu WHERE code='HOT1'), '2026-03-25 10:00:00', 12, (SELECT id FROM lieu WHERE code='AIR')),

(2004, (SELECT id FROM lieu WHERE code='HOT1'), '2026-03-25 10:00:00', 8, (SELECT id FROM lieu WHERE code='AIR'));

COMMIT;

-- Vérification rapide
SELECT 'DONE: inserted variant 2 sample data' AS info;
SELECT * FROM voiture ORDER BY id;
SELECT id, idclient, nombrepassagers, TO_CHAR(datearrivee, 'YYYY-MM-DD HH24:MI') AS when FROM reservation ORDER BY datearrivee;
