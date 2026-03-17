ALTER TABLE voiture ADD COLUMN vitesse_moyenne DECIMAL(10,2);
ALTER TABLE voiture ADD COLUMN temp_attente DECIMAL(10,2);

ALTER TABLE reservation
    ADD COLUMN idLieuAtterissage INTEGER REFERENCES lieu(id);

UPDATE reservation
SET idLieuAtterissage = (
    SELECT l.id FROM lieu l
    JOIN type_lieu tl ON CAST(l.type_lieu AS INTEGER) = tl.id
    WHERE tl.libelle = 'AEROPORT'
    ORDER BY l.id ASC
    LIMIT 1
)
WHERE idLieuAtterissage IS NULL;

-- V\u00e9rification
SELECT r.id, r.idclient, l.libelle AS destination, la.libelle AS aeroport_atterrissage
FROM reservation r
JOIN lieu l  ON r.idlieu             = l.id
JOIN lieu la ON r.idlieuatterissage  = la.id
LIMIT 10;
