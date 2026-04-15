-- ============================================================
-- SCRIPT DE TEST : Cas complexe backlog + split + depart immediat
-- Date de test : 26/03/2026
-- ============================================================
--
-- Objectifs du test:
-- 1. Avoir plusieurs voitures disponibles simultanement avec des capacites differentes.
-- 2. Tester le split des passagers entre plusieurs voitures dans un meme groupe.
-- 3. Tester la priorite des reservations en attente (backlog) sur les nouvelles reservations.
-- 4. Tester le depart immediat d'une voiture quand elle est pleine avec uniquement des passagers en attente.
-- 5. Tester un second recompute avec plusieurs voitures revenant en meme temps.
--
-- SCENARIO ATTENDU:
-- - Groupe 1 (08:00 - 08:20): surcharge forte -> backlog apres remplissage.
-- - Toutes les voitures sont disponibles a partir de 08:20.
-- - Les trajets de groupe 1 font revenir plusieurs voitures vers 09:20.
-- - A 09:20, une voiture de 5 places est remplie uniquement par le backlog et part immediatement,
--   sans attendre les reservations nouvelles de 09:10 / 09:40.
-- - Les reservations nouvelles de 09:10 / 09:40 sont ensuite regroupees avec les voitures restantes.
-- - Groupe 3 (11:00 - 11:15) sert a verifier que le processus continue normalement apres recompute.
-- ============================================================

-- ── 0. REINITIALISATION COMPLETE ─────────────────────────
TRUNCATE TABLE reservation, distance, lieu, type_lieu, voiture, parametre, token
    RESTART IDENTITY CASCADE;

-- ── 1. TYPES DE LIEU ─────────────────────────────────────
INSERT INTO type_lieu (libelle) VALUES ('AEROPORT');
INSERT INTO type_lieu (libelle) VALUES ('HOTEL');

-- ── 2. LIEUX ─────────────────────────────────────────────
INSERT INTO lieu (code, libelle, type_lieu) VALUES
('AIR',  'Aeroport Ivato', (SELECT id FROM type_lieu WHERE libelle = 'AEROPORT')),
('HOT1', 'Hotel Alpha',    (SELECT id FROM type_lieu WHERE libelle = 'HOTEL')),
('HOT2', 'Hotel Beta',     (SELECT id FROM type_lieu WHERE libelle = 'HOTEL')),
('HOT3', 'Hotel Gamma',    (SELECT id FROM type_lieu WHERE libelle = 'HOTEL')),
('HOT4', 'Hotel Delta',    (SELECT id FROM type_lieu WHERE libelle = 'HOTEL'));

-- ── 3. DISTANCES ─────────────────────────────────────────
-- Tous les trajets aéroport -> hôtel sont a 30 km (aller simple)
-- Cela donne environ 60 min aller-retour a 60 km/h.
INSERT INTO distance (lieu_from, lieu_to, km)
SELECT a.id, b.id, 30.00
FROM lieu a, lieu b
WHERE a.code = 'AIR' AND b.code IN ('HOT1', 'HOT2', 'HOT3', 'HOT4');

-- Distances entre hotels pour enrichir l'itineraire
INSERT INTO distance (lieu_from, lieu_to, km)
SELECT a.id, b.id, 8.00
FROM lieu a, lieu b
WHERE a.code = 'HOT1' AND b.code = 'HOT2';

INSERT INTO distance (lieu_from, lieu_to, km)
SELECT a.id, b.id, 12.00
FROM lieu a, lieu b
WHERE a.code = 'HOT2' AND b.code = 'HOT3';

INSERT INTO distance (lieu_from, lieu_to, km)
SELECT a.id, b.id, 6.00
FROM lieu a, lieu b
WHERE a.code = 'HOT3' AND b.code = 'HOT4';

INSERT INTO distance (lieu_from, lieu_to, km)
SELECT a.id, b.id, 10.00
FROM lieu a, lieu b
WHERE a.code = 'HOT1' AND b.code = 'HOT4';

-- ── 4. PARAMETRES ────────────────────────────────────────
INSERT INTO parametre (libelle, valeur) VALUES ('TA', '30');
INSERT INTO parametre (libelle, valeur) VALUES ('vitesse', '60');

-- ── 5. VOITURES ──────────────────────────────────────────
-- Capacite totale = 4 + 4 + 5 + 6 + 7 + 8 = 34 places
-- Toutes les voitures deviennent disponibles en meme temps a 08:20.
INSERT INTO voiture (
    matricule, marque, model, nombre_place, type_carburant,
    vitesse_moyenne, temp_attente, depart_heure_disponibilite
) VALUES
('CMP04D', 'Toyota',   'Yaris',    4, 'D', 60.00, 5.00, '2026-03-26 08:20:00'),
('CMP04E', 'Honda',    'Fit',      4, 'E', 60.00, 5.00, '2026-03-26 08:20:00'),
('CMP05D', 'Mercedes', 'Vito',     5, 'D', 60.00, 5.00, '2026-03-26 08:20:00'),
('CMP06E', 'Nissan',   'Urvan',    6, 'E', 60.00, 5.00, '2026-03-26 08:20:00'),
('CMP07D', 'Ford',     'Transit',  7, 'D', 60.00, 5.00, '2026-03-26 08:20:00'),
('CMP08E', 'Iveco',    'Daily',    8, 'E', 60.00, 5.00, '2026-03-26 08:20:00');

-- ── 6. RESERVATIONS DU 26/03/2026 ────────────────────────
-- Toutes les reservations ont le meme aeroport d'atterrissage.

-- GROUPE 1 : surcharge initiale et split
-- Total reservations = 10 + 9 + 8 + 7 + 5 = 39 passagers
-- Capacite totale = 34 -> backlog attendu = 5 passagers

-- R1 : 10 passagers - 08:00 - Hotel Alpha
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (501,
        (SELECT id FROM lieu WHERE code = 'HOT1'),
        '2026-03-26 08:00:00', 10,
        (SELECT id FROM lieu WHERE code = 'AIR'));

-- R2 : 9 passagers - 08:05 - Hotel Beta
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (502,
        (SELECT id FROM lieu WHERE code = 'HOT2'),
        '2026-03-26 08:05:00', 9,
        (SELECT id FROM lieu WHERE code = 'AIR'));

-- R3 : 8 passagers - 08:10 - Hotel Gamma
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (503,
        (SELECT id FROM lieu WHERE code = 'HOT3'),
        '2026-03-26 08:10:00', 8,
        (SELECT id FROM lieu WHERE code = 'AIR'));

-- R4 : 7 passagers - 08:15 - Hotel Delta
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (504,
        (SELECT id FROM lieu WHERE code = 'HOT4'),
        '2026-03-26 08:15:00', 7,
        (SELECT id FROM lieu WHERE code = 'AIR'));

-- R5 : 5 passagers - 08:20 - Hotel Alpha
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (505,
        (SELECT id FROM lieu WHERE code = 'HOT1'),
        '2026-03-26 08:20:00', 5,
        (SELECT id FROM lieu WHERE code = 'AIR'));

-- GROUPE 2 : reserves en attente + nouvelles reservations
-- Ce groupe doit verifier:
-- - backlog prioritaire
-- - depart immediat si une voiture est pleine uniquement avec backlog
-- - pas d'attente inutile du TA si la voiture est deja pleine

-- R6 : 2 passagers - 09:10 - Hotel Beta
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (506,
        (SELECT id FROM lieu WHERE code = 'HOT2'),
        '2026-03-26 09:10:00', 2,
        (SELECT id FROM lieu WHERE code = 'AIR'));

-- R7 : 3 passagers - 09:40 - Hotel Gamma
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (507,
        (SELECT id FROM lieu WHERE code = 'HOT3'),
        '2026-03-26 09:40:00', 3,
        (SELECT id FROM lieu WHERE code = 'AIR'));

-- GROUPE 3 : verification d'un nouveau cycle normal apres recompute
-- R8 : 11:00 - 6 passagers - Hotel Delta
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (508,
        (SELECT id FROM lieu WHERE code = 'HOT4'),
        '2026-03-26 11:00:00', 6,
        (SELECT id FROM lieu WHERE code = 'AIR'));

-- R9 : 11:15 - 1 passager - Hotel Alpha
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (509,
        (SELECT id FROM lieu WHERE code = 'HOT1'),
        '2026-03-26 11:15:00', 1,
        (SELECT id FROM lieu WHERE code = 'AIR'));

-- ── 7. VERIFICATIONS ─────────────────────────────────────
SELECT '=== PARAMETRES ===' AS info;
SELECT * FROM parametre ORDER BY libelle;

SELECT '=== VOITURES COMPLEXES ===' AS info;
SELECT matricule, nombre_place, type_carburant, vitesse_moyenne, temp_attente, depart_heure_disponibilite
FROM voiture
ORDER BY nombre_place ASC, matricule;

SELECT '=== DISTANCES ===' AS info;
SELECT lf.code AS de, lt.code AS vers, d.km
FROM distance d
JOIN lieu lf ON d.lieu_from = lf.id
JOIN lieu lt ON d.lieu_to = lt.id
ORDER BY lf.code, lt.code;

SELECT '=== RESERVATIONS DU 2026-03-26 ===' AS info;
SELECT r.id, r.idclient, r.nombrepassagers AS pass,
       l.libelle AS destination,
       la.libelle AS aeroport,
       TO_CHAR(r.datearrivee, 'HH24:MI') AS heure
FROM reservation r
JOIN lieu l ON r.idlieu = l.id
LEFT JOIN lieu la ON r.idlieuatterissage = la.id
WHERE DATE(r.datearrivee) = '2026-03-26'
ORDER BY r.datearrivee, r.nombrepassagers DESC;

SELECT '=== RESUME ATTENDU ===' AS info;
SELECT 'Groupe 1: surcharge de 39 passagers pour 34 places -> 5 passagers en attente' AS attendu
UNION ALL SELECT 'Groupe 2: les 5 passagers en attente doivent etre prioritaires a 09:20'
UNION ALL SELECT 'Groupe 2: une voiture de 5 places peut partir immediatement si elle est pleine avec le backlog'
UNION ALL SELECT 'Groupe 3: doit recomposer un nouveau cycle normal apres le backlog';

