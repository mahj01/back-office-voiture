# PostgreSQL - Connexion et execution des scripts

## Pourquoi tu as cette erreur
Tu as lance:

```bash
psql -U app_dev -d voiture_reservation
```

Erreur:

```text
FATAL: Peer authentication failed for user "app_dev"
```

Ca veut dire que PostgreSQL essaie une authentification `peer` (utilisateur Linux = utilisateur PostgreSQL). Comme ton utilisateur Linux est `antonio` et pas `app_dev`, la connexion est refusee.

## Methode 1 (recommandee) : se connecter avec mot de passe via localhost
Utilise TCP au lieu du socket local:

```bash
psql -h localhost -p 5432 -U app_dev -d voiture_reservation
```

PostgreSQL te demandera le mot de passe de `app_dev`.

## Si tu ne connais pas le mot de passe de `app_dev`
Connecte-toi en superuser postgres, puis redefinis le mot de passe.

```bash
sudo -u postgres psql
```

Dans le prompt `psql`:

```sql
ALTER ROLE app_dev WITH PASSWORD 'TonMotDePasseFort';
\q
```

Ensuite reconnecte-toi:

```bash
psql -h localhost -p 5432 -U app_dev -d voiture_reservation
```

## Verifier rapidement la connexion
Une fois connecte:

```sql
\conninfo
\dt
```

## Lancer un script SQL du projet
Depuis la racine du projet (`back-office-voiture`):

```bash
psql -h localhost -p 5432 -U app_dev -d voiture_reservation -f database-scripts/03-12_test_donner_csv.sql
```

Tu peux remplacer le nom du fichier par n'importe quel script dans `database-scripts/`.

## Option pratique (eviter de retaper le mot de passe)

```bash
export PGPASSWORD='TonMotDePasseFort'
psql -h localhost -p 5432 -U app_dev -d voiture_reservation -f database-scripts/03-12_test_donner_csv.sql
unset PGPASSWORD
```

## Si ca bloque encore
Verifier l'etat du service PostgreSQL:

```bash
sudo systemctl status postgresql
```

Demarrer si necessaire:

```bash
sudo systemctl start postgresql
```
