-- ============================================================
-- SCRIPT DE TEST : Regroupement de réservations + assignation voiture
-- Date de test : 2026-07-03
-- ============================================================
-- Scénario :
--   TA (temps d'attente) = 30 minutes
--
--   GROUPE 1 : [08:00 – 08:30]
--     R1  08:00  2 pass  → Hôtel Colbert
--     R2  08:10  3 pass  → Hôtel Carlton
--     R3  08:25  1 pass  → Gare Soarano
--     Total = 6 pass → voiture 8 places (la plus proche >= 6)
--
--   GROUPE 2 : [09:00 – 09:30]
--     R4  09:00  4 pass  → Hôtel Colbert
--     R5  09:15  3 pass  → Hôtel Carlton
--     Total = 7 pass → voiture 8 places
--
--   GROUPE 3 : [10:30] (seule, 45 min après R5)
--     R6  10:30  5 pass  → Hôtel Colbert
--     Total = 5 pass → voiture 5 places
--
--   GROUPE 4 : [12:00 – 12:30]
--     R7  12:00  4 pass  → Gare Soarano
--     R8  12:20  4 pass  → Hôtel Carlton
--     Total = 8 pass → voiture 8 places
--
--   GROUPE 5 : [14:00] (seule)
--     R9  14:00  10 pass → Hôtel Colbert
--     Total = 10 pass → voiture 10 places
--
--   GROUPE 6 : [15:30 – 16:00]
--     R10 15:30  2 pass  → Hôtel Carlton
--     R11 15:50  1 pass  → Gare Soarano
--     Total = 3 pass → voiture 5 places
-- ============================================================

-- ── 0. NETTOYAGE ─────────────────────────────────────────
DELETE FROM reservation WHERE idclient BETWEEN 201 AND 211;

-- ── 1. PARAMÈTRE : temps d'attente = 30 min ─────────────
INSERT INTO parametre (libelle, valeur) VALUES ('TA', '30')
  ON CONFLICT DO NOTHING;
UPDATE parametre SET valeur = '30' WHERE LOWER(libelle) = 'ta';

-- ── 2. DISTANCES (si pas encore présentes) ───────────────
DELETE FROM distance
WHERE (lieu_from IN (SELECT id FROM lieu WHERE code IN ('AIR','HOT1','HOT2','GAR'))
   AND lieu_to   IN (SELECT id FROM lieu WHERE code IN ('AIR','HOT1','HOT2','GAR')));

-- Aéroport Ivato ↔ Hôtel Colbert : 15 km
INSERT INTO distance (lieu_from, lieu_to, km)
SELECT a.id, b.id, 15.00
FROM lieu a, lieu b WHERE a.code = 'AIR' AND b.code = 'HOT1';

-- Aéroport Ivato ↔ Hôtel Carlton : 12 km
INSERT INTO distance (lieu_from, lieu_to, km)
SELECT a.id, b.id, 12.00
FROM lieu a, lieu b WHERE a.code = 'AIR' AND b.code = 'HOT2';

-- Aéroport Ivato ↔ Gare Soarano : 18 km
INSERT INTO distance (lieu_from, lieu_to, km)
SELECT a.id, b.id, 18.00
FROM lieu a, lieu b WHERE a.code = 'AIR' AND b.code = 'GAR';

-- Hôtel Colbert ↔ Hôtel Carlton : 5 km
INSERT INTO distance (lieu_from, lieu_to, km)
SELECT a.id, b.id, 5.00
FROM lieu a, lieu b WHERE a.code = 'HOT1' AND b.code = 'HOT2';

-- Hôtel Colbert ↔ Gare Soarano : 8 km
INSERT INTO distance (lieu_from, lieu_to, km)
SELECT a.id, b.id, 8.00
FROM lieu a, lieu b WHERE a.code = 'HOT1' AND b.code = 'GAR';

-- Hôtel Carlton ↔ Gare Soarano : 7 km
INSERT INTO distance (lieu_from, lieu_to, km)
SELECT a.id, b.id, 7.00
FROM lieu a, lieu b WHERE a.code = 'HOT2' AND b.code = 'GAR';

-- ── 3. VOITURES ──────────────────────────────────────────
-- S'assurer qu'on a suffisamment de voitures variées
-- (ne pas supprimer les existantes, juste compléter si nécessaire)
INSERT INTO voiture (matricule, marque, model, nombre_place, type_carburant, vitesse_moyenne, temp_attente)
VALUES
  ('JUL01A', 'Toyota',   'Yaris',    5,  'G', 40.00, 5.00),
  ('JUL02B', 'Honda',    'Jazz',     5,  'D', 38.00, 5.00),
  ('JUL03C', 'Mercedes', 'Vito',     8,  'D', 45.00, 5.00),
  ('JUL04D', 'Toyota',   'HiAce',   8,  'G', 42.00, 5.00),
  ('JUL05E', 'Hyundai',  'H1',      8,  'D', 40.00, 5.00),
  ('JUL06F', 'Toyota',   'Coaster', 10, 'D', 35.00, 5.00),
  ('JUL07G', 'Ford',     'Transit', 10, 'G', 38.00, 5.00)
ON CONFLICT (matricule) DO NOTHING;

-- ── 4. RÉSERVATIONS DU 2026-07-03 ───────────────────────

-- GROUPE 1 attendu : [08:00 – 08:30] → 6 pass → voiture 8 places
-- R1 : 08:00 - 2 passagers - Hôtel Colbert
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (201,
        (SELECT id FROM lieu WHERE code = 'HOT1' LIMIT 1),
        '2026-07-03 08:00:00', 2,
        (SELECT id FROM lieu WHERE code = 'AIR' LIMIT 1));

-- R2 : 08:10 - 3 passagers - Hôtel Carlton
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (202,
        (SELECT id FROM lieu WHERE code = 'HOT2' LIMIT 1),
        '2026-07-03 08:10:00', 3,
        (SELECT id FROM lieu WHERE code = 'AIR' LIMIT 1));

-- R3 : 08:25 - 1 passager - Gare Soarano
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (203,
        (SELECT id FROM lieu WHERE code = 'GAR' LIMIT 1),
        '2026-07-03 08:25:00', 1,
        (SELECT id FROM lieu WHERE code = 'AIR' LIMIT 1));

-- GROUPE 2 attendu : [09:00 – 09:30] → 7 pass → voiture 8 places
-- R4 : 09:00 - 4 passagers - Hôtel Colbert
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (204,
        (SELECT id FROM lieu WHERE code = 'HOT1' LIMIT 1),
        '2026-07-03 09:00:00', 4,
        (SELECT id FROM lieu WHERE code = 'AIR' LIMIT 1));

-- R5 : 09:15 - 3 passagers - Hôtel Carlton
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (205,
        (SELECT id FROM lieu WHERE code = 'HOT2' LIMIT 1),
        '2026-07-03 09:15:00', 3,
        (SELECT id FROM lieu WHERE code = 'AIR' LIMIT 1));

-- GROUPE 3 attendu : [10:30] seule → 5 pass → voiture 5 places
-- R6 : 10:30 - 5 passagers - Hôtel Colbert (45 min après R5, hors intervalle)
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (206,
        (SELECT id FROM lieu WHERE code = 'HOT1' LIMIT 1),
        '2026-07-03 10:30:00', 5,
        (SELECT id FROM lieu WHERE code = 'AIR' LIMIT 1));

-- GROUPE 4 attendu : [12:00 – 12:30] → 8 pass → voiture 8 places
-- R7 : 12:00 - 4 passagers - Gare Soarano
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (207,
        (SELECT id FROM lieu WHERE code = 'GAR' LIMIT 1),
        '2026-07-03 12:00:00', 4,
        (SELECT id FROM lieu WHERE code = 'AIR' LIMIT 1));

-- R8 : 12:20 - 4 passagers - Hôtel Carlton
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (208,
        (SELECT id FROM lieu WHERE code = 'HOT2' LIMIT 1),
        '2026-07-03 12:20:00', 4,
        (SELECT id FROM lieu WHERE code = 'AIR' LIMIT 1));

-- GROUPE 5 attendu : [14:00] seule → 10 pass → voiture 10 places
-- R9 : 14:00 - 10 passagers - Hôtel Colbert
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (209,
        (SELECT id FROM lieu WHERE code = 'HOT1' LIMIT 1),
        '2026-07-03 14:00:00', 10,
        (SELECT id FROM lieu WHERE code = 'AIR' LIMIT 1));

-- GROUPE 6 attendu : [15:30 – 16:00] → 3 pass → voiture 5 places
-- R10 : 15:30 - 2 passagers - Hôtel Carlton
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (210,
        (SELECT id FROM lieu WHERE code = 'HOT2' LIMIT 1),
        '2026-07-03 15:30:00', 2,
        (SELECT id FROM lieu WHERE code = 'AIR' LIMIT 1));

-- R11 : 15:50 - 1 passager - Gare Soarano
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (211,
        (SELECT id FROM lieu WHERE code = 'GAR' LIMIT 1),
        '2026-07-03 15:50:00', 1,
        (SELECT id FROM lieu WHERE code = 'AIR' LIMIT 1));

-- ── 5. VÉRIFICATION ──────────────────────────────────────
SELECT '=== PARAMÈTRE TEMPS ATTENTE ===' AS info;
SELECT * FROM parametre WHERE LOWER(libelle) = 'ta';

SELECT '=== VOITURES DISPONIBLES ===' AS info;
SELECT id, matricule, marque, model, nombre_place, type_carburant, vitesse_moyenne, temp_attente
FROM voiture ORDER BY nombre_place, type_carburant;

SELECT '=== DISTANCES ===' AS info;
SELECT lf.code AS de, lt.code AS vers, d.km
FROM distance d
JOIN lieu lf ON d.lieu_from = lf.id
JOIN lieu lt ON d.lieu_to   = lt.id
WHERE lf.code IN ('AIR','HOT1','HOT2','GAR')
  AND lt.code IN ('AIR','HOT1','HOT2','GAR')
ORDER BY lf.code, lt.code;

SELECT '=== RÉSERVATIONS DU 2026-07-03 (triées date DESC) ===' AS info;
SELECT r.id, r.idclient, r.nombrepassagers AS pass,
       l.libelle AS destination, la.libelle AS aeroport,
       TO_CHAR(r.datearrivee, 'HH24:MI') AS heure
FROM reservation r
JOIN lieu l  ON r.idlieu = l.id
LEFT JOIN lieu la ON r.idlieuatterissage = la.id
WHERE DATE(r.datearrivee) = '2026-07-03'
ORDER BY r.datearrivee DESC;

SELECT '=== GROUPES ATTENDUS (TA=30min) ===' AS info;
SELECT 'Grp 1: R1(08:00)+R2(08:10)+R3(08:25) =  6 pass → voiture  8 places' AS attendu
UNION ALL SELECT 'Grp 2: R4(09:00)+R5(09:15)          =  7 pass → voiture  8 places'
UNION ALL SELECT 'Grp 3: R6(10:30)                     =  5 pass → voiture  5 places'
UNION ALL SELECT 'Grp 4: R7(12:00)+R8(12:20)          =  8 pass → voiture  8 places'
UNION ALL SELECT 'Grp 5: R9(14:00)                     = 10 pass → voiture 10 places'
UNION ALL SELECT 'Grp 6: R10(15:30)+R11(15:50)        =  3 pass → voiture  5 places';
