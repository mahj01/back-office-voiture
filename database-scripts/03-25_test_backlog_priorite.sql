-- ============================================================
-- SCRIPT DE TEST : Priorite des reservations en attente (backlog)
-- Date de test : 25/03/2026
-- ============================================================
--
-- Objectifs du test:
-- 1. Verifier qu'une reservation non assignee reste en attente.
-- 2. Verifier qu'une voiture revenue prend d'abord les reservations en attente.
-- 3. Verifier qu'un nouveau groupe ne passe pas avant les reservations en attente.
-- 4. Verifier qu'une voiture revenue peut attendre le TA si elle n'est pas encore pleine.
--
-- SCENARIO ATTENDU:
-- - Groupe 1 (08:00 - 08:20): demande totale > capacite totale disponible
--   => il reste des passagers en attente.
-- - Groupe 2 (09:10 - 09:40): arrive apres le retour d'une voiture.
--   => les reservations en attente sont traitees avant les nouvelles.
-- - Si la voiture revenue n'est pas pleine apres la reservation en attente,
--   elle attend les reservations suivantes dans la fenetre TA.
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
('HOT2', 'Hotel Beta',     (SELECT id FROM type_lieu WHERE libelle = 'HOTEL'));

-- ── 3. DISTANCES ─────────────────────────────────────────
-- A/R = 60 km pour un trajet d'environ 1 heure a 60 km/h
INSERT INTO distance (lieu_from, lieu_to, km)
SELECT a.id, b.id, 30.00
FROM lieu a, lieu b
WHERE a.code = 'AIR' AND b.code IN ('HOT1', 'HOT2');

INSERT INTO distance (lieu_from, lieu_to, km)
SELECT a.id, b.id, 12.00
FROM lieu a, lieu b
WHERE a.code = 'HOT1' AND b.code = 'HOT2';

-- ── 4. PARAMETRES ────────────────────────────────────────
INSERT INTO parametre (libelle, valeur) VALUES ('TA', '30');
INSERT INTO parametre (libelle, valeur) VALUES ('vitesse', '60');

-- ── 5. VOITURES ──────────────────────────────────────────
-- Capacité totale = 8 + 4 + 4 = 16 places
-- Le groupe 1 demande 18 passagers, donc 2 restent en attente.
INSERT INTO voiture (matricule, marque, model, nombre_place, type_carburant, vitesse_moyenne, temp_attente) VALUES
('BLK01', 'Toyota',   'HiAce',  8, 'D', 60.00, 5.00),
('BLK02', 'Honda',    'Jazz',   4, 'E', 60.00, 5.00),
('BLK03', 'Mercedes', 'Vito',   4, 'D', 60.00, 5.00);

-- ── 6. RESERVATIONS DU 25/03/2026 ────────────────────────
-- Toutes les reservations ont le meme aeroport d'atterrissage.

-- GROUPE 1 : surcharge de capacite
-- R1 : 7 passagers - 08:00
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (401,
        (SELECT id FROM lieu WHERE code = 'HOT1'),
        '2026-03-25 08:00:00', 7,
        (SELECT id FROM lieu WHERE code = 'AIR'));

-- R2 : 6 passagers - 08:10
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (402,
        (SELECT id FROM lieu WHERE code = 'HOT2'),
        '2026-03-25 08:10:00', 6,
        (SELECT id FROM lieu WHERE code = 'AIR'));

-- R3 : 5 passagers - 08:20
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (403,
        (SELECT id FROM lieu WHERE code = 'HOT1'),
        '2026-03-25 08:20:00', 5,
        (SELECT id FROM lieu WHERE code = 'AIR'));

-- GROUPE 2 : doit prioriser les reservations en attente avant les nouvelles
-- R4 : 1 passager - 09:10
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (404,
        (SELECT id FROM lieu WHERE code = 'HOT2'),
        '2026-03-25 09:10:00', 1,
        (SELECT id FROM lieu WHERE code = 'AIR'));

-- R5 : 1 passager - 09:40
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (405,
        (SELECT id FROM lieu WHERE code = 'HOT1'),
        '2026-03-25 09:40:00', 1,
        (SELECT id FROM lieu WHERE code = 'AIR'));

-- GROUPE 3 : test apres consommation du backlog
-- R6 : 4 passagers - 11:00
INSERT INTO reservation (idClient, idLieu, dateArrivee, nombrePassagers, idLieuAtterissage)
VALUES (406,
        (SELECT id FROM lieu WHERE code = 'HOT2'),
        '2026-03-25 11:00:00', 4,
        (SELECT id FROM lieu WHERE code = 'AIR'));

-- ── 7. VERIFICATIONS ─────────────────────────────────────
SELECT '=== PARAMETRES ===' AS info;
SELECT * FROM parametre ORDER BY libelle;

SELECT '=== VOITURES ===' AS info;
SELECT matricule, nombre_place, type_carburant, vitesse_moyenne, temp_attente
FROM voiture
ORDER BY nombre_place DESC, type_carburant;

SELECT '=== DISTANCES ===' AS info;
SELECT lf.code AS de, lt.code AS vers, d.km
FROM distance d
JOIN lieu lf ON d.lieu_from = lf.id
JOIN lieu lt ON d.lieu_to = lt.id
ORDER BY lf.code, lt.code;

SELECT '=== RESERVATIONS DU 2026-03-25 ===' AS info;
SELECT r.id, r.idclient, r.nombrepassagers AS pass,
       l.libelle AS destination,
       la.libelle AS aeroport,
       TO_CHAR(r.datearrivee, 'HH24:MI') AS heure
FROM reservation r
JOIN lieu l ON r.idlieu = l.id
LEFT JOIN lieu la ON r.idlieuatterissage = la.id
WHERE DATE(r.datearrivee) = '2026-03-25'
ORDER BY r.datearrivee;

SELECT '=== RESUME ATTENDU ===' AS info;
SELECT 'Groupe 1: 18 passagers pour 16 places -> 2 en attente' AS attendu
UNION ALL SELECT 'Groupe 2: les reservations en attente sont traitees avant R4/R5'
UNION ALL SELECT 'Vehicle revenue: prend les reservations en attente, puis attend TA si le groupe n''est pas complet'
UNION ALL SELECT 'Groupe 3: doit etre traite normalement apres le backlog';
