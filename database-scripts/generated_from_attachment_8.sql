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
('HOT1', 'Hotel1', (SELECT id FROM type_lieu WHERE libelle='HOTEL')),
('HOT2', 'Hotel2', (SELECT id FROM type_lieu WHERE libelle='HOTEL')),
('HOT3', 'Hotel3', (SELECT id FROM type_lieu WHERE libelle='HOTEL'))

ON CONFLICT DO NOTHING;

-- Distance observée : 50 km (Aéroport -> Hotel1)
INSERT INTO distance (lieu_from, lieu_to, km)
SELECT a.id, b.id, 90.00
FROM lieu a, lieu b
WHERE a.code = 'AIR' AND b.code = 'HOT1'
ON CONFLICT (lieu_from, lieu_to) DO NOTHING;

INSERT INTO distance (lieu_from, lieu_to, km)
SELECT a.id, b.id, 65.00
FROM lieu a, lieu b
WHERE a.code = 'AIR' AND b.code = 'HOT2'
ON CONFLICT (lieu_from, lieu_to) DO NOTHING;

INSERT INTO distance (lieu_from, lieu_to, km)
SELECT a.id, b.id, 10.00
FROM lieu a, lieu b
WHERE a.code = 'HOT1' AND b.code = 'HOT2'
ON CONFLICT (lieu_from, lieu_to) DO NOTHING;

-- Paramètres (temps attente en minutes, vitesse en km/h)
INSERT INTO parametre (libelle, valeur) VALUES ('TA', '30') ON CONFLICT DO NOTHING;
INSERT INTO parametre (libelle, valeur) VALUES ('vitesse', '60') ON CONFLICT DO NOTHING;

-- Véhicule unique observé dans la capture
INSERT INTO voiture (matricule, marque, model, nombre_place, type_carburant, vitesse_moyenne, temp_attente, depart_heure_disponibilite)
VALUES
('VEHICLE1', 'Generic', 'Van10', 10, 'D', 60.00, 30.00, '2026-04-02 00:00:00')
ON CONFLICT DO NOTHING;

INSERT INTO voiture (matricule, marque, model, nombre_place, type_carburant, vitesse_moyenne, temp_attente, depart_heure_disponibilite)
VALUES
    ('VEHICLE2', 'Generic', 'Van10', 8, 'D', 60.00, 30.00, '2026-04-02 08:00:00')
ON CONFLICT DO NOTHING;

INSERT INTO voiture (matricule, marque, model, nombre_place, type_carburant, vitesse_moyenne, temp_attente, depart_heure_disponibilite)
VALUES
    ('VEHICLE3', 'Generic', 'Van10', 8, 'E', 60.00, 30.00, '2026-04-02 08:00:00')
ON CONFLICT DO NOTHING;
INSERT INTO voiture (matricule, marque, model, nombre_place, type_carburant, vitesse_moyenne, temp_attente, depart_heure_disponibilite)
VALUES
    ('VEHICLE4', 'Generic', 'Van10', 12, 'E', 60.00, 30.00, '2026-04-02 09:00:00')
ON CONFLICT DO NOTHING;


-- Réservations (date 25/03/2026, heures et tailles selon la capture)
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES
(1, (SELECT id FROM lieu WHERE code='HOT1'), '2026-04-02 06:00:00', 20, (SELECT id FROM lieu WHERE code='AIR')),
(2, (SELECT id FROM lieu WHERE code='HOT1'), '2026-04-02 08:15:00', 6, (SELECT id FROM lieu WHERE code='AIR')),
(3, (SELECT id FROM lieu WHERE code='HOT1'), '2026-04-02 09:00:00', 10, (SELECT id FROM lieu WHERE code='AIR')),

(4, (SELECT id FROM lieu WHERE code='HOT2'), '2026-04-02 09:10:00', 6, (SELECT id FROM lieu WHERE code='AIR'));

COMMIT;


