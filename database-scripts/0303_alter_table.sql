-- ================================
-- 1) TABLE parametre
-- ================================

CREATE TABLE parametre (
    id SERIAL PRIMARY KEY,
    libelle VARCHAR(255) NOT NULL,
    valeur VARCHAR(255) NOT NULL
);

-- ================================
-- 2) RENOMMER hotel EN lieu
-- ================================

ALTER TABLE hotel RENAME TO lieu;

-- ================================
-- 3) MODIFICATION TABLE lieu
-- ================================

-- Supprimer colonne nom
ALTER TABLE lieu DROP COLUMN nom;

-- Ajouter nouvelles colonnes
ALTER TABLE lieu ADD COLUMN code VARCHAR(255) NOT NULL;
ALTER TABLE lieu ADD COLUMN libelle VARCHAR(255) NOT NULL;
ALTER TABLE lieu ADD COLUMN type_lieu VARCHAR(255) NOT NULL;

-- ================================
-- 4) TABLE distance
-- ================================

CREATE TABLE distance (
    id SERIAL PRIMARY KEY,
    lieu_from INT NOT NULL,
    lieu_to INT NOT NULL,
    km DOUBLE PRECISION NOT NULL,
    CONSTRAINT fk_lieu_from
        FOREIGN KEY (lieu_from)
        REFERENCES lieu(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_lieu_to
        FOREIGN KEY (lieu_to)
        REFERENCES lieu(id)
        ON DELETE CASCADE
);