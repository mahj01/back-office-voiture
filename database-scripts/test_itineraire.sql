-- ============================================================
-- SCRIPT DE TEST : Itinéraire aller-retour
-- ============================================================
-- Scénario :
--   Voiture utilisée : première voiture disponible (ex. mat001) → vitesse_moyenne forcée à 40 km/h
--   Itinéraire : Aéroport (réel) → Hôtel Alpha → Hôtel Beta → Aéroport
--   Distances  : Aéro→Alpha = 10 km | Alpha→Beta = 6 km | Beta→Aéro = 12 km
--   Distance totale aller-retour = 10 + 6 + 12 = 28 km
--   Temps conduite  = 28 / 40 × 60 = 42 min
--   Temps attente   = 2 arrêts × 5 min = 10 min  (temp_attente ignoré ici)
--   Temps total (sans attente) = 42 min
--   Départ 08:00 → Retour estimé 08:42
-- NOTE : le code Java utilise le VRAI aéroport (ORDER BY id ASC),
--        les distances doivent donc partir de son ID réel.
-- ============================================================

-- ── 0. RESET données de test ─────────────────────────────
DELETE FROM reservation WHERE idclient IN (9901, 9902);
DELETE FROM distance
  WHERE lieu_from IN (SELECT id FROM lieu WHERE code LIKE 'TEST_%')
     OR lieu_to   IN (SELECT id FROM lieu WHERE code LIKE 'TEST_%');
DELETE FROM lieu WHERE code LIKE 'TEST_%';

-- ── 1. SAUVEGARDER et configurer la voiture (la 1re voiture disponible) ──
-- On sauvegarde les valeurs actuelles dans une table temporaire
CREATE TEMP TABLE IF NOT EXISTS _test_voiture_backup AS
  SELECT id, vitesse_moyenne, temp_attente
  FROM voiture
  ORDER BY nombre_place DESC, type_carburant
  LIMIT 1;

-- Forcer vitesse_moyenne=40 et temp_attente=5 sur cette voiture pour le test
UPDATE voiture
SET vitesse_moyenne = 40.00,
    temp_attente    = 5.00
WHERE id = (SELECT id FROM _test_voiture_backup);

-- ── 2. INSÉRER les lieux hôtels de test ──────────────────
INSERT INTO lieu (code, libelle, type_lieu) VALUES
  ('TEST_HOTEL_A', 'Hôtel Alpha', (SELECT id FROM type_lieu WHERE libelle = 'HOTEL' LIMIT 1)),
  ('TEST_HOTEL_B', 'Hôtel Beta',  (SELECT id FROM type_lieu WHERE libelle = 'HOTEL' LIMIT 1));

-- ── 3. INSÉRER les distances depuis le VRAI aéroport ─────
-- (getAeroport() Java → ORDER BY id ASC LIMIT 1 → aéroport original)

-- Aéroport réel → Hôtel Alpha : 10 km
INSERT INTO distance (lieu_from, lieu_to, km)
SELECT aero.id, ha.id, 10.00
FROM lieu aero, lieu ha
WHERE aero.id = (
        SELECT l.id FROM lieu l
        JOIN type_lieu tl ON CAST(l.type_lieu AS INTEGER) = tl.id
        WHERE tl.libelle = 'AEROPORT'
        ORDER BY l.id ASC LIMIT 1
      )
  AND ha.code = 'TEST_HOTEL_A';

-- Hôtel Alpha → Hôtel Beta : 6 km
INSERT INTO distance (lieu_from, lieu_to, km)
SELECT ha.id, hb.id, 6.00
FROM lieu ha, lieu hb
WHERE ha.code = 'TEST_HOTEL_A' AND hb.code = 'TEST_HOTEL_B';

-- Hôtel Beta → Aéroport réel : 12 km
INSERT INTO distance (lieu_from, lieu_to, km)
SELECT hb.id, aero.id, 12.00
FROM lieu hb, lieu aero
WHERE hb.code = 'TEST_HOTEL_B'
  AND aero.id = (
        SELECT l.id FROM lieu l
        JOIN type_lieu tl ON CAST(l.type_lieu AS INTEGER) = tl.id
        WHERE tl.libelle = 'AEROPORT'
        ORDER BY l.id ASC LIMIT 1
      );

-- ── 4. INSÉRER les réservations de test (date : demain) ──
INSERT INTO reservation (idclient, idlieu, datearrivee, nombrepassagers)
SELECT 9901, l.id, (CURRENT_DATE + INTERVAL '1 day')::timestamp + TIME '08:00:00', 3
FROM lieu l WHERE l.code = 'TEST_HOTEL_A';

INSERT INTO reservation (idclient, idlieu, datearrivee, nombrepassagers)
SELECT 9902, l.id, (CURRENT_DATE + INTERVAL '1 day')::timestamp + TIME '08:00:00', 2
FROM lieu l WHERE l.code = 'TEST_HOTEL_B';

-- ── 5. VÉRIFICATION DES DONNÉES INSÉRÉES ─────────────────
SELECT '=== AÉROPORT UTILISÉ (ORDER BY id ASC) ===' AS info;
SELECT l.id, l.code, l.libelle
FROM lieu l
JOIN type_lieu tl ON CAST(l.type_lieu AS INTEGER) = tl.id
WHERE tl.libelle = 'AEROPORT'
ORDER BY l.id ASC LIMIT 1;

SELECT '=== VOITURE CONFIGURÉE POUR LE TEST ===' AS info;
SELECT v.id, v.matricule, v.marque, v.model, v.nombre_place, v.type_carburant, v.vitesse_moyenne, v.temp_attente
FROM voiture v
WHERE v.id = (SELECT id FROM _test_voiture_backup);

SELECT '=== LIEUX DE TEST ===' AS info;
SELECT l.id, l.code, l.libelle, tl.libelle AS type
FROM lieu l
JOIN type_lieu tl ON CAST(l.type_lieu AS INTEGER) = tl.id
WHERE l.code LIKE 'TEST_%';

SELECT '=== DISTANCES DE TEST ===' AS info;
SELECT lf.libelle AS de, lt.libelle AS vers, d.km
FROM distance d
JOIN lieu lf ON d.lieu_from = lf.id
JOIN lieu lt ON d.lieu_to   = lt.id
WHERE lf.code LIKE 'TEST_%' OR lt.code LIKE 'TEST_%'
   OR lf.id = (SELECT l.id FROM lieu l JOIN type_lieu tl ON CAST(l.type_lieu AS INTEGER) = tl.id WHERE tl.libelle = 'AEROPORT' ORDER BY l.id ASC LIMIT 1)
ORDER BY lf.code, lt.code;

SELECT '=== RÉSERVATIONS DE TEST ===' AS info;
SELECT r.id, r.idclient, l.libelle AS lieu, r.datearrivee, r.nombrepassagers
FROM reservation r
JOIN lieu l ON r.idlieu = l.id
WHERE r.idclient IN (9901, 9902);

-- ── 6. SIMULATION DU CALCUL (SQL pur) ─────────────────────
SELECT '=== SIMULATION CALCUL ITINÉRAIRE ===' AS info;

WITH aero AS (
    SELECT l.id FROM lieu l
    JOIN type_lieu tl ON CAST(l.type_lieu AS INTEGER) = tl.id
    WHERE tl.libelle = 'AEROPORT' ORDER BY l.id ASC LIMIT 1
),
params AS (
    SELECT
        v.vitesse_moyenne                        AS vitesse_kmh,
        v.temp_attente                           AS attente_min_par_arret,
        -- distance réelle depuis la table
        (SELECT d.km FROM distance d, lieu ha
         WHERE d.lieu_from = (SELECT id FROM aero) AND ha.code='TEST_HOTEL_A' AND d.lieu_to=ha.id)
        +
        (SELECT d.km FROM distance d, lieu ha, lieu hb
         WHERE ha.code='TEST_HOTEL_A' AND hb.code='TEST_HOTEL_B'
           AND d.lieu_from=ha.id AND d.lieu_to=hb.id)
        +
        (SELECT d.km FROM distance d, lieu hb
         WHERE hb.code='TEST_HOTEL_B' AND d.lieu_from=hb.id
           AND d.lieu_to=(SELECT id FROM aero))  AS distance_totale_km,
        2                                         AS nb_arrets
    FROM voiture v WHERE v.id = (SELECT id FROM _test_voiture_backup)
),
calcul AS (
    SELECT
        vitesse_kmh,
        attente_min_par_arret,
        distance_totale_km,
        nb_arrets,
        ROUND((distance_totale_km / vitesse_kmh * 60)::numeric, 1)        AS temps_conduite_min,
        (nb_arrets * attente_min_par_arret)                                AS temps_attente_min,
        ROUND((distance_totale_km / vitesse_kmh * 60
               + nb_arrets * attente_min_par_arret)::numeric, 1)          AS temps_total_min
    FROM params
)
SELECT
    vitesse_kmh                                                AS "Vitesse (km/h)",
    distance_totale_km                                         AS "Distance totale (km)",
    nb_arrets                                                  AS "Nb arrêts",
    attente_min_par_arret                                      AS "Attente/arrêt (min)",
    temps_conduite_min                                         AS "Temps conduite (min)",
    temps_attente_min                                          AS "Temps attente (min)",
    temps_total_min                                            AS "Temps total (min)",
    TIME '08:00:00' + (temps_total_min || ' minutes')::interval AS "Heure retour estimée"
FROM calcul;

-- ── 7. RÉSULTAT ATTENDU ────────────────────────────────────
SELECT '=== RÉSULTAT ATTENDU ===' AS info;
SELECT
    '28 km'  AS distance_totale,
    '42 min' AS temps_conduite,
    '10 min' AS temps_attente,
    '52 min' AS temps_total,
    '08:52'  AS heure_retour_estimee;

-- ── 8. NETTOYAGE ──────────────────────────────────────────
-- Décommenter pour nettoyer après le test :
-- DELETE FROM reservation WHERE idclient IN (9901, 9902);
-- DELETE FROM distance
--   WHERE lieu_from IN (SELECT id FROM lieu WHERE code LIKE 'TEST_%')
--      OR lieu_to   IN (SELECT id FROM lieu WHERE code LIKE 'TEST_%');
-- DELETE FROM distance
--   WHERE lieu_to   IN (SELECT id FROM lieu WHERE code LIKE 'TEST_%');
-- DELETE FROM lieu WHERE code LIKE 'TEST_%';
-- Restaurer les valeurs originales de la voiture :
-- UPDATE voiture SET vitesse_moyenne = (SELECT vitesse_moyenne FROM _test_voiture_backup),
--                    temp_attente    = (SELECT temp_attente    FROM _test_voiture_backup)
-- WHERE id = (SELECT id FROM _test_voiture_backup);
-- DROP TABLE IF EXISTS _test_voiture_backup;
