-- reinit_truncate.sql
-- Script de reinitialisation : efface toutes les donnees et remet les sequences (SERIAL) a 1.
-- Usage : psql -U app_dev -d voiture_reservation -f reinit_truncate.sql

-- TRUNCATE efface les donnees, RESTART IDENTITY remet les SERIAL a 1,
-- CASCADE gere automatiquement les dependances FK.

TRUNCATE TABLE reservation, distance, lieu, type_lieu, voiture, parametre, token
    RESTART IDENTITY CASCADE;

-- =====================================================
-- VERIFICATION : toutes les tables sont vides
-- =====================================================
SELECT 'reservation'  AS table_name, COUNT(*) AS nb_rows FROM reservation
UNION ALL
SELECT 'distance',    COUNT(*) FROM distance
UNION ALL
SELECT 'lieu',        COUNT(*) FROM lieu
UNION ALL
SELECT 'type_lieu',   COUNT(*) FROM type_lieu
UNION ALL
SELECT 'voiture',     COUNT(*) FROM voiture
UNION ALL
SELECT 'parametre',   COUNT(*) FROM parametre
UNION ALL
SELECT 'token',       COUNT(*) FROM token;

