-- ============================================================
-- SCRIPT DE TEST SPRINT 6 : Priorité par nombre de trajets
-- ============================================================
-- Teste les nouvelles règles de gestion:
-- 1. Priorité aux voitures avec le moins de trajets
-- 2. Disponibilité selon l'heure de retour
-- 3. Réassignation après retour des voitures
-- 4. Ajustement de l'heure de départ
--
-- Usage:
-- psql -h localhost -U app_dev -d voiture_reservation -f database-scripts/03-17_test_nombre_trajets.sql

BEGIN;

-- ── 0. NETTOYAGE ─────────────────────────────────────────
DELETE FROM reservation WHERE idclient IN (201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213);
DELETE FROM voiture WHERE matricule IN ('TEST-D5', 'TEST-E5', 'TEST-D8', 'TEST-E30');

-- ── 1. VÉRIFIER / INSÉRER le paramètre TA ────────────────
INSERT INTO parametre (libelle, valeur) VALUES ('TA', '30')
  ON CONFLICT DO NOTHING;
UPDATE parametre SET valeur = '30' WHERE LOWER(libelle) = 'ta';

-- ── 2. VÉRIFIER les lieux existants ──────────────────────
-- S'assurer que les lieux de test existent
INSERT INTO type_lieu (libelle) VALUES ('AEROPORT') ON CONFLICT (libelle) DO NOTHING;
INSERT INTO type_lieu (libelle) VALUES ('HOTEL') ON CONFLICT (libelle) DO NOTHING;

INSERT INTO lieu (code, libelle, type_lieu)
SELECT 'AIR', 'Aéroport Ivato', (SELECT id FROM type_lieu WHERE libelle = 'AEROPORT')
WHERE NOT EXISTS (SELECT 1 FROM lieu WHERE code = 'AIR');

INSERT INTO lieu (code, libelle, type_lieu)
SELECT 'HOT1', 'Hôtel Colbert', (SELECT id FROM type_lieu WHERE libelle = 'HOTEL')
WHERE NOT EXISTS (SELECT 1 FROM lieu WHERE code = 'HOT1');

INSERT INTO lieu (code, libelle, type_lieu)
SELECT 'HOT2', 'Hôtel Carlton', (SELECT id FROM type_lieu WHERE libelle = 'HOTEL')
WHERE NOT EXISTS (SELECT 1 FROM lieu WHERE code = 'HOT2');

INSERT INTO lieu (code, libelle, type_lieu)
SELECT 'HOT3', 'Hôtel Panorama', (SELECT id FROM type_lieu WHERE libelle = 'HOTEL')
WHERE NOT EXISTS (SELECT 1 FROM lieu WHERE code = 'HOT3');

-- ── 3. DISTANCES entre les lieux ─────────────────────────
DELETE FROM distance
WHERE (lieu_from IN (SELECT id FROM lieu WHERE code IN ('AIR','HOT1','HOT2','HOT3'))
   AND lieu_to   IN (SELECT id FROM lieu WHERE code IN ('AIR','HOT1','HOT2','HOT3')));

-- Aéroport Ivato ↔ Hôtel Colbert : 15 km (30 min aller-retour à 30 km/h)
INSERT INTO distance (lieu_from, lieu_to, km)
SELECT a.id, b.id, 15.00
FROM lieu a, lieu b WHERE a.code = 'AIR' AND b.code = 'HOT1';

-- Aéroport Ivato ↔ Hôtel Carlton : 12 km (24 min aller-retour à 30 km/h)
INSERT INTO distance (lieu_from, lieu_to, km)
SELECT a.id, b.id, 12.00
FROM lieu a, lieu b WHERE a.code = 'AIR' AND b.code = 'HOT2';

-- Aéroport Ivato ↔ Hôtel Panorama : 20 km (40 min aller-retour à 30 km/h)
INSERT INTO distance (lieu_from, lieu_to, km)
SELECT a.id, b.id, 20.00
FROM lieu a, lieu b WHERE a.code = 'AIR' AND b.code = 'HOT3';

-- Hôtel Colbert ↔ Hôtel Carlton : 5 km
INSERT INTO distance (lieu_from, lieu_to, km)
SELECT a.id, b.id, 5.00
FROM lieu a, lieu b WHERE a.code = 'HOT1' AND b.code = 'HOT2';

-- Hôtel Colbert ↔ Hôtel Panorama : 8 km
INSERT INTO distance (lieu_from, lieu_to, km)
SELECT a.id, b.id, 8.00
FROM lieu a, lieu b WHERE a.code = 'HOT1' AND b.code = 'HOT3';

-- Hôtel Carlton ↔ Hôtel Panorama : 10 km
INSERT INTO distance (lieu_from, lieu_to, km)
SELECT a.id, b.id, 10.00
FROM lieu a, lieu b WHERE a.code = 'HOT2' AND b.code = 'HOT3';

-- ── 4. VOITURES DE TEST ──────────────────────────────────
-- 2 voitures avec 5 places (une diesel, une essence) pour tester la priorité trajets
INSERT INTO voiture (matricule, marque, model, nombre_place, type_carburant, vitesse_moyenne, temp_attente)
VALUES ('TEST-D5', 'Toyota', 'Hiace', 5, 'D', 30.00, 5.00);

INSERT INTO voiture (matricule, marque, model, nombre_place, type_carburant, vitesse_moyenne, temp_attente)
VALUES ('TEST-E5', 'Nissan', 'Urvan', 5, 'E', 30.00, 5.00);

-- 1 voiture avec 8 places diesel pour les groupes plus grands
INSERT INTO voiture (matricule, marque, model, nombre_place, type_carburant, vitesse_moyenne, temp_attente)
VALUES ('TEST-D8', 'Mercedes', 'Sprinter', 8, 'D', 30.00, 5.00);

-- 1 voiture avec 30 places pour tester le cas spécial (grande capacité)
INSERT INTO voiture (matricule, marque, model, nombre_place, type_carburant, vitesse_moyenne, temp_attente)
VALUES ('TEST-E30', 'Iveco', 'Daily', 30, 'E', 25.00, 10.00);

-- ── 5. RÉSERVATIONS DE TEST ──────────────────────────────
-- Date de test: 2026-03-18

-- SCÉNARIO 1: Test de la priorité par nombre de trajets
-- -------------------------------------------------------
-- R1: 04:00 - 3 passagers - Hôtel Colbert
-- Attendu: Voiture TEST-D5 (diesel prioritaire, même capacité, 0 trajet)
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (201,
        (SELECT id FROM lieu WHERE code = 'HOT1'),
        '2026-03-18 04:00:00', 3,
        (SELECT id FROM lieu WHERE code = 'AIR'));

-- R2: 05:30 - 3 passagers - Hôtel Carlton
-- TEST-D5 revient vers 05:00 (4h + 60 min trajet aller-retour)
-- Attendu: TEST-E5 car TEST-D5 a déjà fait 1 trajet, TEST-E5 a fait 0 trajet
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (202,
        (SELECT id FROM lieu WHERE code = 'HOT2'),
        '2026-03-18 05:30:00', 3,
        (SELECT id FROM lieu WHERE code = 'AIR'));

-- R3: 07:00 - 3 passagers - Hôtel Panorama
-- TEST-D5 a fait 1 trajet, TEST-E5 a fait 1 trajet -> à égalité, diesel prioritaire
-- Attendu: TEST-D5 (diesel)
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (203,
        (SELECT id FROM lieu WHERE code = 'HOT3'),
        '2026-03-18 07:00:00', 3,
        (SELECT id FROM lieu WHERE code = 'AIR'));

-- SCÉNARIO 2: Test de disponibilité selon heure de retour
-- -------------------------------------------------------
-- R4: 04:30 - 4 passagers - Hôtel Colbert
-- La voiture TEST-D5 est partie à 04:00, elle revient vers 05:00
-- TEST-E5 et TEST-D8 sont disponibles
-- Attendu: TEST-E5 (5 places, moins de surplus que TEST-D8 à 8 places)
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (204,
        (SELECT id FROM lieu WHERE code = 'HOT1'),
        '2026-03-18 04:30:00', 4,
        (SELECT id FROM lieu WHERE code = 'AIR'));

-- SCÉNARIO 3: Grande réservation qui nécessite une grande voiture
-- -------------------------------------------------------
-- R5: 08:00 - 28 passagers - Hôtel Carlton
-- Seule TEST-E30 (30 places) peut prendre cette réservation
-- Attendu: TEST-E30
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (205,
        (SELECT id FROM lieu WHERE code = 'HOT2'),
        '2026-03-18 08:00:00', 28,
        (SELECT id FROM lieu WHERE code = 'AIR'));

-- SCÉNARIO 4: Attente de retour de voiture
-- -------------------------------------------------------
-- R6: 05:00 - 28 passagers - Hôtel Panorama
-- TEST-E30 est parti à 04:30 et revient vers ~05:30
-- Attendu: Attendre TEST-E30, départ à 05:30+ au lieu de 05:00
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (206,
        (SELECT id FROM lieu WHERE code = 'HOT3'),
        '2026-03-18 05:00:00', 28,
        (SELECT id FROM lieu WHERE code = 'AIR'));

-- SCÉNARIO 5: Regroupement dans fenêtre de temps (TA=30min)
-- -------------------------------------------------------
-- R7: 10:00 - 2 passagers - Hôtel Colbert
-- R8: 10:15 - 2 passagers - Hôtel Carlton
-- R9: 10:25 - 1 passager - Hôtel Panorama
-- Tous dans la fenêtre [10:00, 10:30], total 5 passagers
-- Attendu: Regroupés dans une voiture 5 places, départ 10:25
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (207,
        (SELECT id FROM lieu WHERE code = 'HOT1'),
        '2026-03-18 10:00:00', 2,
        (SELECT id FROM lieu WHERE code = 'AIR'));

INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (208,
        (SELECT id FROM lieu WHERE code = 'HOT2'),
        '2026-03-18 10:15:00', 2,
        (SELECT id FROM lieu WHERE code = 'AIR'));

INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (209,
        (SELECT id FROM lieu WHERE code = 'HOT3'),
        '2026-03-18 10:25:00', 1,
        (SELECT id FROM lieu WHERE code = 'AIR'));

-- R10: 11:00 - Réservation isolée hors fenêtre
-- Attendu: Nouvelle assignation séparée
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (210,
        (SELECT id FROM lieu WHERE code = 'HOT1'),
        '2026-03-18 11:00:00', 3,
        (SELECT id FROM lieu WHERE code = 'AIR'));

-- SCÉNARIO 6: Report au prochain groupe (RG-T9)
-- -------------------------------------------------------
-- Ce scénario teste que les réservations non assignées sont reportées
-- au prochain groupe NATUREL, pas à l'heure de retour de la voiture.
--
-- R11: 12:00 - 28 passagers - Hôtel Colbert
-- R12: 12:05 - 28 passagers - Hôtel Carlton (dans la même fenêtre)
-- Seule TEST-E30 peut prendre 28 passagers, mais un seul trajet à la fois
-- TEST-E30 prend R11 (départ 12:05 car il y a R12 dans la fenêtre)
-- TEST-E30 revient vers ~13:30 (après 80+ min de trajet)
-- R12 n'a plus de voiture disponible à 12:05
--
-- R13: 15:00 - 2 passagers - Hôtel Panorama (prochain groupe naturel)
--
-- ATTENDU: R12 est reportée au groupe de 15:00 (R13), pas à 13:30
-- Départ de R12+R13 = 15:00 (pas 13:30)

INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (211,
        (SELECT id FROM lieu WHERE code = 'HOT1'),
        '2026-03-18 12:00:00', 28,
        (SELECT id FROM lieu WHERE code = 'AIR'));

INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (212,
        (SELECT id FROM lieu WHERE code = 'HOT2'),
        '2026-03-18 12:05:00', 28,
        (SELECT id FROM lieu WHERE code = 'AIR'));

INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (213,
        (SELECT id FROM lieu WHERE code = 'HOT3'),
        '2026-03-18 15:00:00', 2,
        (SELECT id FROM lieu WHERE code = 'AIR'));

COMMIT;

-- ── 6. VÉRIFICATION ──────────────────────────────────────
SELECT '=== PARAMÈTRE TEMPS ATTENTE ===' as info;
SELECT * FROM parametre WHERE LOWER(libelle) = 'ta';

SELECT '=== VOITURES DE TEST ===' as info;
SELECT id, matricule, marque, model, nombre_place, type_carburant, vitesse_moyenne
FROM voiture
WHERE matricule LIKE 'TEST-%'
ORDER BY nombre_place, type_carburant;

SELECT '=== DISTANCES ENTRE LIEUX ===' as info;
SELECT lf.code AS de_code, lt.code AS vers_code, d.km,
       ROUND(d.km * 2 / 30.0 * 60, 0) AS temps_aller_retour_min
FROM distance d
JOIN lieu lf ON d.lieu_from = lf.id
JOIN lieu lt ON d.lieu_to   = lt.id
WHERE lf.code = 'AIR'
ORDER BY d.km;

SELECT '=== RÉSERVATIONS DU 2026-03-18 ===' as info;
SELECT r.id, r.idclient, r.nombrepassagers, l.libelle AS destination,
       TO_CHAR(r.datearrivee, 'HH24:MI') AS heure,
       CASE
         WHEN r.nombrepassagers <= 5 THEN 'Voiture 5 places'
         WHEN r.nombrepassagers <= 8 THEN 'Voiture 8 places'
         ELSE 'Voiture 30 places'
       END AS voiture_requise
FROM reservation r
JOIN lieu l ON r.idlieu = l.id
WHERE DATE(r.datearrivee) = '2026-03-18'
ORDER BY r.datearrivee;

SELECT '=== RÉSULTATS ATTENDUS ===' as info;
SELECT 'Scénario 1: R1(04:00) → TEST-D5 (diesel, 0 trajet)' AS attendu
UNION ALL SELECT 'Scénario 1: R2(05:30) → TEST-E5 (essence, 0 trajet car TEST-D5 a 1 trajet)'
UNION ALL SELECT 'Scénario 1: R3(07:00) → TEST-D5 (diesel prioritaire, égalité 1 trajet)'
UNION ALL SELECT 'Scénario 2: R4(04:30) → TEST-E5 ou TEST-D8 (TEST-D5 en trajet)'
UNION ALL SELECT 'Scénario 3: R5(08:00) → TEST-E30 (seule avec 30 places)'
UNION ALL SELECT 'Scénario 4: R6(05:00) → TEST-E30, départ retardé (attend retour voiture)'
UNION ALL SELECT 'Scénario 5: R7+R8+R9 → Regroupés, départ 10:25 (dernier passager)'
UNION ALL SELECT 'Scénario 5: R10(11:00) → Assignation séparée (hors fenêtre 30min)'
UNION ALL SELECT 'Scénario 6: R11(12:00) → TEST-E30 (28 passagers)'
UNION ALL SELECT 'Scénario 6: R12(12:05) → Reportée au groupe de 15:00 (pas à 13:30)'
UNION ALL SELECT 'Scénario 6: R12+R13 → Regroupées, départ 15:00 (prochain groupe naturel)';
