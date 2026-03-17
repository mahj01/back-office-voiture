CREATE TABLE voiture (
    id SERIAL PRIMARY KEY,
    matricule VARCHAR(50) NOT NULL UNIQUE,
    marque VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    nombre_place INTEGER NOT NULL,
    type_carburant VARCHAR(2) NOT NULL
);
INSERT INTO voiture (matricule, marque, model, nombre_place, type_carburant) VALUES
('1234AB', 'Toyota', 'Corolla', 5, 'G'),
('5678CD', 'Honda', 'Civic', 5, 'D'),
('9012EF', 'Ford', 'Focus', 5, 'E'),
('3456GH', 'Chevrolet', 'Malibu', 5, 'G'),
('7890IJ', 'Nissan', 'Sentra', 5, 'D');