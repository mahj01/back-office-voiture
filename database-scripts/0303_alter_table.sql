create table parametre(
    id int auto_increment primary key,
    libelle varchar(255) not null,
    valeur varchar(255) not null
);

rename table hotel to lieu;

alter table lieu drop column nom;
alter table lieu add column code varchar(255) not null;
alter table lieu add column libelle varchar(255) not null;
alter table lieu add column type_lieu varchar(255) not null;

create table distance (
    id int auto_increment primary key,
    "from" int not null,
    "to" int not null,
    km double not null,
    foreign key ("from") references lieu(id),
    foreign key ("to") references lieu(id)
);
