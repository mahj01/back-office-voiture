

-- ── 0. NETTOYAGE ─────────────────────────────────────────
DELETE FROM reservation WHERE idclient IN (101, 102, 103, 104, 105, 106, 107, 108);

-- ── 1. VÉRIFIER / INSÉRER le paramètre TA ────────────────
-- S'assurer que le temps d'attente = 30 min est en base
INSERT INTO parametre (libelle, valeur) VALUES ('TA', '30')
  ON CONFLICT DO NOTHING;
-- Ou mettre à jour si existe déjà
UPDATE parametre SET valeur = '30' WHERE LOWER(libelle) = 'ta';

-- ── 2. VÉRIFIER les lieux existants ──────────────────────
-- On utilise les lieux déjà existants (script 0403)
-- AIR = Aéroport Ivato, HOT1 = Hôtel Colbert, HOT2 = Hôtel Carlton, GAR = Gare Soarano

-- ── 2b. DISTANCES entre les lieux utilisés ───────────────
-- Supprimer les anciennes distances entre ces lieux pour éviter les doublons
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

-- ── 3. VOITURES (utiliser celles déjà en base, ou réinsérer si nécessaire)
-- S'assurer qu'on a des voitures avec vitesse_moyenne et temp_attente
UPDATE voiture SET vitesse_moyenne = 40.00, temp_attente = 30.00 WHERE vitesse_moyenne IS NULL;


INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (101,
        (SELECT id FROM lieu WHERE code = 'HOT1' LIMIT 1),
        '2026-03-15 08:00:00', 2,
        (SELECT id FROM lieu WHERE code = 'AIR' LIMIT 1));

-- R2: 08:10 - 3 passagers - Hôtel Carlton
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (102,
        (SELECT id FROM lieu WHERE code = 'HOT2' LIMIT 1),
        '2026-03-15 08:10:00', 3,
        (SELECT id FROM lieu WHERE code = 'AIR' LIMIT 1));

-- R3: 08:25 - 1 passager - Gare Soarano
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (103,
        (SELECT id FROM lieu WHERE code = 'GAR' LIMIT 1),
        '2026-03-15 08:25:00', 1,
        (SELECT id FROM lieu WHERE code = 'AIR' LIMIT 1));

-- GROUPE 2 attendu : [09:00 - 09:30]
-- R4: 09:00 - 4 passagers - Hôtel Colbert
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (104,
        (SELECT id FROM lieu WHERE code = 'HOT1' LIMIT 1),
        '2026-03-15 09:00:00', 4,
        (SELECT id FROM lieu WHERE code = 'AIR' LIMIT 1));

-- R5: 09:20 - 2 passagers - Hôtel Carlton
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (105,
        (SELECT id FROM lieu WHERE code = 'HOT2' LIMIT 1),
        '2026-03-15 09:20:00', 2,
        (SELECT id FROM lieu WHERE code = 'AIR' LIMIT 1));

-- GROUPE 3 attendu : seule (aucune autre dans les 30 min)
-- R6: 11:00 - 5 passagers - Hôtel Colbert
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (106,
        (SELECT id FROM lieu WHERE code = 'HOT1' LIMIT 1),
        '2026-03-15 11:00:00', 5,
        (SELECT id FROM lieu WHERE code = 'AIR' LIMIT 1));

-- GROUPE 4 attendu : seule (45 min après R6, hors intervalle)
-- R7: 11:45 - 3 passagers - Gare Soarano
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (107,
        (SELECT id FROM lieu WHERE code = 'GAR' LIMIT 1),
        '2026-03-15 11:45:00', 3,
        (SELECT id FROM lieu WHERE code = 'AIR' LIMIT 1));

-- GROUPE 5 attendu : seule (isolée à 14h)
-- R8: 14:00 - 6 passagers - Hôtel Carlton
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (108,
        (SELECT id FROM lieu WHERE code = 'HOT2' LIMIT 1),
        '2026-03-15 14:00:00', 6,
        (SELECT id FROM lieu WHERE code = 'AIR' LIMIT 1));

-- ── 5. VÉRIFICATION ──────────────────────────────────────
SELECT '=== PARAMÈTRE TEMPS ATTENTE ===' as info;
SELECT * FROM parametre WHERE LOWER(libelle) = 'ta';

SELECT '=== VOITURES DISPONIBLES ===' as info;
SELECT id, matricule, marque, model, nombre_place, type_carburant, vitesse_moyenne, temp_attente
FROM voiture ORDER BY nombre_place, type_carburant;

SELECT '=== DISTANCES ENTRE LIEUX ===' as info;
SELECT lf.code AS de_code, lf.libelle AS de, lt.code AS vers_code, lt.libelle AS vers, d.km
FROM distance d
JOIN lieu lf ON d.lieu_from = lf.id
JOIN lieu lt ON d.lieu_to   = lt.id
WHERE lf.code IN ('AIR','HOT1','HOT2','GAR')
  AND lt.code IN ('AIR','HOT1','HOT2','GAR')
ORDER BY lf.code, lt.code;

SELECT '=== RÉSERVATIONS DU 2026-03-15 ===' as info;
SELECT r.id, r.idclient, r.nombrepassagers, l.libelle AS destination,
       la.libelle AS aeroport, r.datearrivee,
       TO_CHAR(r.datearrivee, 'HH24:MI') AS heure
FROM reservation r
JOIN lieu l ON r.idlieu = l.id
LEFT JOIN lieu la ON r.idlieuatterissage = la.id
WHERE DATE(r.datearrivee) = '2026-03-15'
ORDER BY r.datearrivee;

SELECT '=== GROUPES ATTENDUS (TA=30min) ===' as info;
SELECT 'Groupe 1: R1(08:00) + R2(08:10) + R3(08:25) = 6 pass → 1 voiture 8 places' AS attendu
UNION ALL SELECT 'Groupe 2: R4(09:00) + R5(09:20) = 6 pass → 1 voiture 8 places'
UNION ALL SELECT 'Groupe 3: R6(11:00) = 5 pass → 1 voiture 5 places'
UNION ALL SELECT 'Groupe 4: R7(11:45) = 3 pass → 1 voiture 5 places'
UNION ALL SELECT 'Groupe 5: R8(14:00) = 6 pass → 1 voiture 8 places';
