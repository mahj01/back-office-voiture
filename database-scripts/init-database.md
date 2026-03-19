# Guide d'initialisation de la base de donnees (DEV)

## Pre-requis

- PostgreSQL installe et en cours d'execution
- Acces avec l'utilisateur `postgres`

## Execution du script

```bash
cd /home/antonio/ITU/S5/mr-naina/voiture/back-office-voiture/database-scripts
psql -U postgres -f init-database.sql
```

## Ce qui est cree

| Element | Description |
|---------|-------------|
| Base | `voiture_reservation` |
| Schema | `dev` |
| Role | `app_dev` (mot de passe: `dev_pwd`) |

### Tables

| Table | Description |
|-------|-------------|
| `type_lieu` | Types de lieux (AEROPORT, HOTEL) |
| `lieu` | Lieux (aeroports, hotels) |
| `voiture` | Vehicules disponibles |
| `reservation` | Reservations des clients |
| `distance` | Distances entre les lieux |
| `parametre` | Parametres de configuration |
| `token` | Tokens d'authentification |

## Connexion

```bash
psql -U app_dev -d voiture_reservation -h localhost
# Mot de passe: dev_pwd
```

## Reinitialisation des donnees

```bash
psql -U app_dev -d voiture_reservation -f reinit_truncate.sql
```

## Schema relationnel

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

## Depannage

### Terminer les connexions actives avant reinitialisation

```sql
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'voiture_reservation' AND pid <> pg_backend_pid();
```
