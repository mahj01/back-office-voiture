-- ============================================================
-- SCRIPT DE TEST : Séparation des passagers d'un client
-- Date de test : 18/03/2026
-- ============================================================
--
-- VEHICULES :
--   v1    8 places   Diesel
--   v2    3 places   Essence
--
-- RESERVATIONS (toutes à 09:00:00 le 18/03/2026, même hôtel) :
--   Client1 (r1)    6 passagers    09:00  hotel1
--   Client2 (r2)    4 passagers    09:00  hotel1
--   Client3 (r3)    3 passagers    09:00  hotel1
--
-- Total passagers = 6 + 4 + 3 = 13
-- Capacité totale = 8 + 3 = 11 places
-- Déficit = 2 passagers (devront attendre le retour d'une voiture)
--
-- Distance aéroport ↔ hotel1 = 50 km
-- Vitesse moyenne = 50 km/h
--
-- RÉSULTAT ATTENDU (avec séparation des passagers) :
--   Tri DESC passagers : r1(6) > r2(4) > r3(3)
--
--   VOITURE v1 (8 places, Diesel) :
--     - r1 : 6 passagers (tous)
--     - r2 : 2 passagers (sur 4)
--     - Total : 8 passagers (voiture pleine)
--
--   VOITURE v2 (3 places, Essence) :
--     - r2 : 2 passagers (restants)
--     - r3 : 1 passager (sur 3)
--     - Total : 3 passagers (voiture pleine)
--
--   NON ASSIGNÉS (attente retour voiture) :
--     - r3 : 2 passagers restants
--
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

-- ── 5. VOITURES ──────────────────────────────────────────
INSERT INTO voiture (matricule, marque, model, nombre_place, type_carburant, vitesse_moyenne, temp_attente) VALUES
('v1', 'Marque1', 'Model1', 8, 'D', 50.00, 5.00),
('v2', 'Marque2', 'Model2', 3, 'E', 50.00, 5.00);

-- ── 6. RÉSERVATIONS DU 18/03/2026 à 09:00 ───────────────
-- Toutes vers Hotel1, départ depuis Aéroport Ivato

-- Client 1 : 6 passagers
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (1,
        (SELECT id FROM lieu WHERE code = 'HOT1'),
        '2026-03-18 09:00:00', 6,
        (SELECT id FROM lieu WHERE code = 'AIR'));

-- Client 2 : 4 passagers
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (2,
        (SELECT id FROM lieu WHERE code = 'HOT1'),
        '2026-03-18 09:00:00', 4,
        (SELECT id FROM lieu WHERE code = 'AIR'));

-- Client 3 : 3 passagers
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (3,
        (SELECT id FROM lieu WHERE code = 'HOT1'),
        '2026-03-18 09:00:00', 3,
        (SELECT id FROM lieu WHERE code = 'AIR'));

-- ── 7. VÉRIFICATION ──────────────────────────────────────
SELECT '=== VOITURES ===' AS info;
SELECT matricule, nombre_place, type_carburant FROM voiture ORDER BY nombre_place DESC, type_carburant;

SELECT '=== RÉSERVATIONS DU 2026-03-18 (tri passagers DESC) ===' AS info;
SELECT r.id, r.idclient, r.nombrepassagers AS pass,
       l.libelle AS destination,
       TO_CHAR(r.datearrivee, 'HH24:MI') AS heure
FROM reservation r
JOIN lieu l ON r.idlieu = l.id
WHERE DATE(r.datearrivee) = '2026-03-18'
ORDER BY r.nombrepassagers DESC;

SELECT '=== RÉSUMÉ ===' AS info;
SELECT 'Total passagers = ' || SUM(nombrepassagers) || ' | Capacité totale voitures = ' ||
       (SELECT SUM(nombre_place) FROM voiture) AS resume
FROM reservation WHERE DATE(datearrivee) = '2026-03-18';

SELECT '=== RÉSULTAT ATTENDU (avec séparation des passagers) ===' AS info;
SELECT 'v1 (8 places D): Client1(6 pass) + Client2(2/4 pass) = 8 passagers' AS attendu
UNION ALL SELECT 'v2 (3 places E): Client2(2/4 pass) + Client3(1/3 pass) = 3 passagers'
UNION ALL SELECT 'Non assignés: Client3(2/3 pass) - attente retour voiture';
