-- ============================================================
-- SCRIPT DE TEST basé sur donner.csv
-- Date de test : 12/03/2026
-- ============================================================
--
-- VEHICULES :
--   vehicule1   12 places   Diesel
--   vehicule2    5 places   Essence
--   vehicule3    5 places   Diesel
--   vehicule4   12 places   Essence
--
-- RESERVATIONS (toutes à 09:00:00 le 12/03/2026, même hôtel) :
--   Client1      7 pass    09:00  hotel1
--   Client2     11 pass    09:00  hotel1
--   Client3      3 pass    09:00  hotel1
--   Client4      1 pass    09:00  hotel1
--   Client5      2 pass    09:00  hotel1
--   Client6     20 pass    09:00  hotel1
--
-- Distance aéroport ↔ hotel1 = 50 km
-- Vitesse moyenne = 50 km/h
--
-- Toutes les réservations sont à la même heure donc 1 seul groupe.
-- Total passagers = 7+11+3+1+2+20 = 44
-- Aucune voiture seule ne suffit (max 12 places).
-- L'algo va former des sous-groupes par capacité :
--
-- RÉSULTAT ATTENDU (tri DESC par date puis passagers) :
--   Tri : Client6(20) > Client2(11) > Client1(7) > Client3(3) > Client5(2) > Client4(1)
--   Groupe unique (même date) → total 44 pass → voiture 12 places (best fit)
--   Reste 32 pass non couverts → 2e voiture 12 places
--   etc. → l'algo distribue selon la logique implémentée
-- ============================================================

-- ── 0. REINITIALISATION COMPLÈTE ─────────────────────────
TRUNCATE TABLE reservation, distance, lieu, type_lieu, voiture, parametre, token
    RESTART IDENTITY CASCADE;

-- ── 1. TYPES DE LIEU ─────────────────────────────────────
INSERT INTO type_lieu (libelle) VALUES ('AEROPORT');
INSERT INTO type_lieu (libelle) VALUES ('HOTEL');

-- ── 2. LIEUX ─────────────────────────────────────────────
INSERT INTO lieu (code, libelle, type_lieu) VALUES
('AIR',   'Aéroport Ivato', (SELECT id FROM type_lieu WHERE libelle = 'AEROPORT')),
('HOT1',  'Hotel1',         (SELECT id FROM type_lieu WHERE libelle = 'HOTEL'));

-- ── 3. DISTANCES ─────────────────────────────────────────
-- Aéroport ↔ Hotel1 : 50 km
INSERT INTO distance (lieu_from, lieu_to, km)
SELECT a.id, b.id, 50.00
FROM lieu a, lieu b WHERE a.code = 'AIR' AND b.code = 'HOT1';

-- ── 4. PARAMÈTRES ────────────────────────────────────────
INSERT INTO parametre (libelle, valeur) VALUES ('TA', '30');
INSERT INTO parametre (libelle, valeur) VALUES ('vitesse', '50');

-- ── 5. VOITURES (exactement comme le CSV) ────────────────
INSERT INTO voiture (matricule, marque, model, nombre_place, type_carburant, vitesse_moyenne, temp_attente) VALUES
('vehicule1', 'Marque1', 'Model1', 12, 'D', 50.00, 5.00),
('vehicule2', 'Marque2', 'Model2',  5, 'E', 50.00, 5.00),
('vehicule3', 'Marque3', 'Model3',  5, 'D', 50.00, 5.00),
('vehicule4', 'Marque4', 'Model4', 12, 'E', 50.00, 5.00);

-- ── 6. RÉSERVATIONS DU 12/03/2026 à 09:00 ───────────────
-- Toutes vers Hotel1, départ depuis Aéroport Ivato

INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (1,
        (SELECT id FROM lieu WHERE code = 'HOT1'),
        '2026-03-12 09:00:00', 7,
        (SELECT id FROM lieu WHERE code = 'AIR'));

INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (2,
        (SELECT id FROM lieu WHERE code = 'HOT1'),
        '2026-03-12 09:00:00', 11,
        (SELECT id FROM lieu WHERE code = 'AIR'));

INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (3,
        (SELECT id FROM lieu WHERE code = 'HOT1'),
        '2026-03-12 09:00:00', 3,
        (SELECT id FROM lieu WHERE code = 'AIR'));

INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (4,
        (SELECT id FROM lieu WHERE code = 'HOT1'),
        '2026-03-12 09:00:00', 1,
        (SELECT id FROM lieu WHERE code = 'AIR'));

INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (5,
        (SELECT id FROM lieu WHERE code = 'HOT1'),
        '2026-03-12 09:00:00', 2,
        (SELECT id FROM lieu WHERE code = 'AIR'));

INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (6,
        (SELECT id FROM lieu WHERE code = 'HOT1'),
        '2026-03-12 09:00:00', 20,
        (SELECT id FROM lieu WHERE code = 'AIR'));

-- ── 7. VÉRIFICATION ──────────────────────────────────────
SELECT '=== VOITURES ===' AS info;
SELECT matricule, nombre_place, type_carburant FROM voiture ORDER BY nombre_place DESC, type_carburant;

SELECT '=== RÉSERVATIONS DU 2026-03-12 (tri passagers DESC) ===' AS info;
SELECT r.id, r.idclient, r.nombrepassagers AS pass,
       l.libelle AS destination,
       TO_CHAR(r.datearrivee, 'HH24:MI') AS heure
FROM reservation r
JOIN lieu l ON r.idlieu = l.id
WHERE DATE(r.datearrivee) = '2026-03-12'
ORDER BY r.nombrepassagers DESC;

SELECT '=== RÉSUMÉ ===' AS info;
SELECT 'Total passagers = ' || SUM(nombrepassagers) || ' | Capacité totale voitures = ' ||
       (SELECT SUM(nombre_place) FROM voiture) AS resume
FROM reservation WHERE DATE(datearrivee) = '2026-03-12';

SELECT '=== ATTENDU : toutes les réservations même heure → 1 seul groupe ===' AS info;
SELECT 'Groupe unique: 44 passagers total, capacité max voiture = 12' AS attendu
UNION ALL SELECT 'L algo va assigner les voitures par capacité la plus proche du total'
UNION ALL SELECT 'vehicule1 (12 D) et vehicule4 (12 E) pour les gros groupes'
UNION ALL SELECT 'vehicule3 (5 D) et vehicule2 (5 E) pour les petits groupes';
