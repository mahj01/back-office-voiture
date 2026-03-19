# Guide d'initialisation de la base de donnees

## Description

Le script `init-database.sql` permet d'initialiser completement la base de donnees PostgreSQL pour le projet **Voiture Reservation - Back Office**.

## Pre-requis

- PostgreSQL installe et en cours d'execution
- Acces avec un utilisateur ayant les droits de creation de base (ex: `postgres`)

## Structure creee

### Base de donnees
- **voiture_reservation** : Base principale

### Schemas
| Schema    | Description                          |
|-----------|--------------------------------------|
| `dev`     | Environnement de developpement       |
| `staging` | Environnement de pre-production      |
| `prod`    | Environnement de production          |

### Roles et mots de passe
| Role         | Mot de passe  | Schema par defaut |
|--------------|---------------|-------------------|
| `app_dev`    | `dev_pwd`     | dev               |
| `app_staging`| `staging_pwd` | staging           |
| `app_prod`   | `prod_pwd`    | prod              |

### Tables
| Table         | Description                                      |
|---------------|--------------------------------------------------|
| `type_lieu`   | Types de lieux (AEROPORT, HOTEL)                 |
| `lieu`        | Lieux (aeroports, hotels)                        |
| `voiture`     | Vehicules disponibles                            |
| `reservation` | Reservations des clients                         |
| `distance`    | Distances entre les lieux                        |
| `parametre`   | Parametres de configuration (vitesse, temps...)  |
| `token`       | Tokens d'authentification                        |

## Comment executer le script

### Option 1 : Ligne de commande (recommandee)

```bash
# Se placer dans le repertoire des scripts
cd /home/antonio/ITU/S5/mr-naina/voiture/back-office-voiture/database-scripts

# Executer le script en tant que postgres
psql -U postgres -f init-database.sql
```

### Option 2 : Avec mot de passe

```bash
psql -U postgres -h localhost -f init-database.sql
# Entrer le mot de passe postgres quand demande
```

### Option 3 : Via variable d'environnement

```bash
export PGPASSWORD='votre_mot_de_passe_postgres'
psql -U postgres -h localhost -f init-database.sql
```

## Connexion apres initialisation

### Environnement DEV (recommande pour le developpement)

```bash
psql -U app_dev -d voiture_reservation -h localhost
# Mot de passe: dev_pwd
```

### Environnement STAGING

```bash
psql -U app_staging -d voiture_reservation -h localhost
# Mot de passe: staging_pwd
```

### Environnement PROD

```bash
psql -U app_prod -d voiture_reservation -h localhost
# Mot de passe: prod_pwd
```

## Configuration de l'application

Utiliser ces informations dans votre fichier de configuration :

```properties
# DEV
spring.datasource.url=jdbc:postgresql://localhost:5432/voiture_reservation?currentSchema=dev
spring.datasource.username=app_dev
spring.datasource.password=dev_pwd

# STAGING
spring.datasource.url=jdbc:postgresql://localhost:5432/voiture_reservation?currentSchema=staging
spring.datasource.username=app_staging
spring.datasource.password=staging_pwd

# PROD
spring.datasource.url=jdbc:postgresql://localhost:5432/voiture_reservation?currentSchema=prod
spring.datasource.username=app_prod
spring.datasource.password=prod_pwd
```

## Reinitialisation des donnees

Pour vider toutes les tables sans supprimer la structure :

```bash
psql -U app_dev -d voiture_reservation -f reinit_truncate.sql
```

## Schema de la base de donnees

```
type_lieu
    |
    +-- lieu (type_lieu FK)
           |
           +-- reservation (idLieu FK, idLieuAtterissage FK)
           |
           +-- distance (lieu_from FK, lieu_to FK)

voiture (independant)
parametre (independant)
token (independant)
```

## Donnees initiales

Le script insere automatiquement :

- **Types de lieu** : AEROPORT, HOTEL
- **Parametres** :
  - TA (Temps d'attente) : 30 minutes
  - vitesse : 30 km/h

## Depannage

### Erreur "database already exists"
Le script supprime automatiquement la base existante. Verifiez qu'aucune connexion n'est active.

### Erreur "role already exists"
Le script supprime automatiquement les roles existants avant de les recreer.

### Erreur de permission
Assurez-vous d'executer le script avec l'utilisateur `postgres` ou un superutilisateur.

### Terminer les connexions actives

```sql
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'voiture_reservation' AND pid <> pg_backend_pid();
```
