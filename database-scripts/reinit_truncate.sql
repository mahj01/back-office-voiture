-- reinit_truncate.sql
-- Reinitialization script: truncate application tables and reset sequences.
-- Usage: psql -U app_dev -d voiture_reservation -f reinit_truncate.sql

\c voiture_reservation;

-- Truncate known tables across schemas (if they exist). Restart identity sequences and cascade to dependent objects.
TRUNCATE TABLE IF EXISTS
    dev.reservation,
    dev.hotel,
    dev.voiture,
    dev.parametres,
    staging.reservation,
    staging.hotel,
    staging.voiture,
    staging.parametres,
    prod.reservation,
    prod.hotel,
    prod.voiture,
    prod.parametres,
    public.reservation,
    public.hotel,
    public.voiture,
    public.parametres,
    public.token
RESTART IDENTITY CASCADE;

-- Optional quick existence/count checks (returns 0 when the table/schema is missing)
SELECT CASE WHEN to_regclass('dev.hotel') IS NOT NULL THEN (SELECT COUNT(*) FROM dev.hotel) ELSE 0 END AS dev_hotel_count;
SELECT CASE WHEN to_regclass('dev.reservation') IS NOT NULL THEN (SELECT COUNT(*) FROM dev.reservation) ELSE 0 END AS dev_reservation_count;
SELECT CASE WHEN to_regclass('dev.parametres') IS NOT NULL THEN (SELECT COUNT(*) FROM dev.parametres) ELSE 0 END AS dev_parametres_count;
SELECT CASE WHEN to_regclass('public.token') IS NOT NULL THEN (SELECT COUNT(*) FROM public.token) ELSE 0 END AS public_token_count;

-- Note:
-- - This script assumes the database "voiture_reservation" exists and that you have permissions to connect and truncate these tables.
-- - If you use a different schema layout, add or remove schema-qualified table names as appropriate.
-- - TRUNCATE ... RESTART IDENTITY CASCADE will reset SERIAL sequences owned by the truncated columns.

