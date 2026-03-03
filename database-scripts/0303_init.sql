alter table hotel add column code varchar(255) not null;
alter table hotel add column libelle varchar(255) not null;
alter table hotel drop column nom;

