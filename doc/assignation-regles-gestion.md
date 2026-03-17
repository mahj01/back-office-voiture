# Regles de gestion - Assignation des voitures

## Contexte
Cette note explique la logique metier de `AssignationService.assignerVoitures(Date date)` pour affecter des voitures aux reservations d'un jour.

Fichiers lies:
- `backoffice/src/main/java/org/itu/util/AssignationService.java`
- `backoffice/src/main/java/org/itu/controller/AssignationController.java`

## Flux applicatif (controller -> service)
1. L'utilisateur saisit une date via `GET /assignation/saisie`.
2. `POST /assignation/resultat` appelle `assignerVoitures(date)`.
3. Le controller envoie a la vue:
- la liste des assignations
- le nombre total de reservations affectees
- le nombre de voitures utilisees
- le temps d'attente (TA)

## Regles metier appliquees dans `assignerVoitures`
1. Charger les donnees du jour:
- voitures disponibles (`getAllVoitures`)
- reservations de la date (`getReservationsByDate`)
- parametre TA en minutes (`getTempsAttenteMinutes`)

2. Regrouper les reservations par aeroport d'atterrissage:
- cle = `idlieuatterissage`
- si aeroport manquant: groupe `0`

3. Trier chaque groupe de reservations:
- `nombrePassager` decroissant
- puis `dateArrivee` decroissante

4. Affecter les voitures en boucle tant qu'il reste des reservations:
- prendre la reservation principale (la plus "lourde")
- choisir la premiere voiture disponible avec capacite suffisante dans la liste triee par places decroissantes
- calculer la capacite restante
- ajouter d'autres reservations compatibles:
  - ecart de temps <= TA par rapport a la reservation principale
  - nombre de passagers <= capacite restante
- retirer la voiture utilisee du stock disponible

5. Determiner l'heure de depart du groupe:
- depart = heure d'arrivee la plus tardive parmi les reservations du groupe (la voiture attend le dernier passager)

6. Calcul post-traitement pour chaque assignation avec voiture:
- choisir l'aeroport local (sinon aeroport global)
- calculer l'itineraire (`computeItineraire`)
- calculer distance, duree de trajet, heure de retour aeroport

## Important
Le commentaire de classe mentionne une strategie "meilleur fit + diesel + random" (`trouverMeilleureVoiture`).

Mais dans `assignerVoitures`, la strategie reellement appliquee est differente:
- priorite aux plus grandes voitures d'abord (tri decroissant des places)
- prise de la premiere voiture qui peut contenir la reservation principale
- la methode `trouverMeilleureVoiture` n'est pas utilisee dans ce flux

## Exemples rapides
### Exemple 1 - Groupement par TA
Donnees:
- TA = 30 min
- Voiture V1: 9 places
- Reservations (meme aeroport):
  - R1: 6 passagers a 10:00
  - R2: 2 passagers a 10:20
  - R3: 3 passagers a 11:10

Resultat:
- R1 prend V1 (reste 3 places)
- R2 est ajoutee (10:20 est dans la fenetre de 30 min, reste 1 place)
- R3 n'entre pas (hors fenetre et 3 passagers)
- Depart du groupe R1+R2 = 10:20 (dernier passager)

### Exemple 2 - Pas de voiture compatible
Donnees:
- Reservation: 12 passagers
- Plus grande voiture dispo: 9 places

Resultat:
- Une assignation est creee sans voiture (`bestVoiture = null`)
- Cette reservation reste visible dans les resultats mais non couverte

## Resume bref
La methode optimise d'abord le remplissage operationnel par aeroport et par capacite (logique gloutonne), avec une contrainte temporelle TA pour regrouper les passagers proches dans le temps, puis calcule un itineraire et l'heure de retour pour chaque voiture effectivement affectee.
