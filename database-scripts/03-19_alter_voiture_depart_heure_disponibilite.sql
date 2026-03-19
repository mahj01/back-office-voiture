-- Ajoute l'heure de debut de disponibilite des voitures
-- Une voiture n'est candidate qu'a partir de cette date/heure

ALTER TABLE voiture
ADD COLUMN IF NOT EXISTS depart_heure_disponibilite TIMESTAMP;
