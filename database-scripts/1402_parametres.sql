-- 1402_parametres.sql
-- Create parametres table in dev schema and mirror into staging/prod, then insert initial values.

\c voiture_reservation;

CREATE TABLE IF NOT EXISTS dev.parametres (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    valeur VARCHAR(255) NOT NULL
);

-- Mirror for other schemas
CREATE TABLE IF NOT EXISTS staging.parametres (LIKE dev.parametres INCLUDING ALL);
CREATE TABLE IF NOT EXISTS prod.parametres (LIKE dev.parametres INCLUDING ALL);

-- Insert initial parameter values (Vitesse Moyenne, Temps d'attente)
-- Use ON CONFLICT to avoid duplicate inserts when re-running the migration
INSERT INTO dev.parametres (code, valeur) VALUES ('VM', '30')
    ON CONFLICT (code) DO UPDATE SET valeur = EXCLUDED.valeur;
INSERT INTO dev.parametres (code, valeur) VALUES ('TA', '30')
    ON CONFLICT (code) DO UPDATE SET valeur = EXCLUDED.valeur;

-- Optionally mirror inserts into public or other schemas if your app reads from them
INSERT INTO public.parametres (code, valeur)
    SELECT code, valeur FROM dev.parametres
    WHERE to_regclass('public.parametres') IS NOT NULL
    ON CONFLICT (code) DO UPDATE SET valeur = EXCLUDED.valeur;

-- If public.parametres doesn't exist, create it (uncomment if needed):
-- CREATE TABLE IF NOT EXISTS public.parametres (LIKE dev.parametres INCLUDING ALL);

