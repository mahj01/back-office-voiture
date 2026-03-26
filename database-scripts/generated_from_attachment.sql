-- Script généré à partir des données fournies (capture)
-- Adapté au schéma défini dans init-database.sql (schema dev)

SET search_path = dev;

BEGIN;

-- Réinitialisation (optionnel)
TRUNCATE TABLE reservation, distance, lieu, type_lieu, voiture, parametre, token RESTART IDENTITY CASCADE;

-- Lieux
INSERT INTO type_lieu (libelle) VALUES ('AEROPORT') ON CONFLICT DO NOTHING;
INSERT INTO type_lieu (libelle) VALUES ('HOTEL') ON CONFLICT DO NOTHING;

INSERT INTO lieu (code, libelle, type_lieu)
VALUES
('AIR', 'Aeroport Principal', (SELECT id FROM type_lieu WHERE libelle='AEROPORT')),
('HOT1', 'Hotel1', (SELECT id FROM type_lieu WHERE libelle='HOTEL'))
ON CONFLICT DO NOTHING;

-- Distance Aéroport -> Hotel1 (valeur observée dans vos captures: 50 km)
INSERT INTO distance (lieu_from, lieu_to, km)
SELECT a.id, b.id, 50.00
FROM lieu a, lieu b
WHERE a.code = 'AIR' AND b.code = 'HOT1'
ON CONFLICT (lieu_from, lieu_to) DO NOTHING;

-- Paramètres globaux (TA = temps attente en minutes, vitesse en km/h)
INSERT INTO parametre (libelle, valeur) VALUES ('TA', '30') ON CONFLICT DO NOTHING;
INSERT INTO parametre (libelle, valeur) VALUES ('vitesse', '50') ON CONFLICT DO NOTHING;

-- Voitures (exemples tirés des captures)
INSERT INTO voiture (matricule, marque, model, nombre_place, type_carburant, vitesse_moyenne, temp_attente, depart_heure_disponibilite)
VALUES
('vehicule1', 'Generic', 'Van10', 10, 'D', 50.00, 30.00, '2026-03-25 10:00:00'),
('vehicule2', 'Generic', 'Van12', 12, 'D', 50.00, 30.00, '2026-03-25 00:00:00'),
('vehicule3', 'Generic', 'Minibus5', 5, 'D', 50.00, 30.00, '2026-03-25 09:00:00')
ON CONFLICT DO NOTHING;

-- Reservations (extraits et adaptés — idClient arbitraires)
-- Groupe A (matin)
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES
(1, (SELECT id FROM lieu WHERE code='HOT1'), '2026-03-25 08:00:00', 10, (SELECT id FROM lieu WHERE code='AIR')),
(2, (SELECT id FROM lieu WHERE code='HOT1'), '2026-03-25 10:10:00', 15, (SELECT id FROM lieu WHERE code='AIR')),
(3, (SELECT id FROM lieu WHERE code='HOT1'), '2026-03-25 10:15:00', 8, (SELECT id FROM lieu WHERE code='AIR'));

-- Groupe B
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES
(4, (SELECT id FROM lieu WHERE code='HOT1'), '2026-03-25 08:15:00', 5, (SELECT id FROM lieu WHERE code='AIR')),
(5, (SELECT id FROM lieu WHERE code='HOT1'), '2026-03-25 09:00:00', 13, (SELECT id FROM lieu WHERE code='AIR')),
(6, (SELECT id FROM lieu WHERE code='HOT1'), '2026-03-25 11:00:00', 1, (SELECT id FROM lieu WHERE code='AIR'));

-- Autres cas (petits groupes et singletons)
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES
(7, (SELECT id FROM lieu WHERE code='HOT1'), '2026-03-25 12:15:00', 1, (SELECT id FROM lieu WHERE code='AIR')),
(8, (SELECT id FROM lieu WHERE code='HOT1'), '2026-03-25 12:30:00', 2, (SELECT id FROM lieu WHERE code='AIR')),
(9, (SELECT id FROM lieu WHERE code='HOT1'), '2026-03-25 13:00:00', 3, (SELECT id FROM lieu WHERE code='AIR'));

COMMIT;

-- Vérification rapide
SELECT 'DONE: inserted sample data' AS info;
SELECT * FROM voiture ORDER BY id;
SELECT id, idclient, nombrepassagers, datearrivee FROM reservation ORDER BY datearrivee;
