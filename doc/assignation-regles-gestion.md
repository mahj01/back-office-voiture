# Règles de gestion - Assignation des voitures

## Contexte
Cette note décrit la logique métier réellement appliquée par `AssignationService.assignerVoitures(Date date)` après refactorisation.

Fichiers liés:
- `backoffice/src/main/java/org/itu/util/AssignationService.java`
- `backoffice/src/main/java/org/itu/controller/AssignationController.java`

## Flux applicatif (controller -> service)
1. L'utilisateur choisit une date via `GET /assignation/saisie`.
2. `POST /assignation/resultat` appelle `assignerVoitures(date)`.
3. Le controller affiche:
- la liste des assignations,
- le nombre total de réservations affectées,
- le nombre de voitures utilisées,
- le temps d'attente (TA).

## Règles métier actuelles

### 1. Chargement des données
- charger les voitures disponibles (`getAllVoitures`),
- charger les réservations du jour (`getReservationsByDate`),
- charger les paramètres métier (`TA`, vitesse, etc.).

### 2. Regroupement initial
- regrouper les réservations par aéroport d'atterrissage,
- trier les réservations d'un aéroport par heure d'arrivée croissante.

### 3. Construction des groupes
- le premier groupe est construit autour d'une réservation ancre,
- les réservations proches dans une fenêtre de `TA` minutes sont ajoutées,
- les réservations déjà en attente peuvent être réinjectées dans le groupe lors d'un recompute.

### 4. Priorité de traitement des réservations
Dans un groupe actif, les priorités sont les suivantes:
1. une réservation déjà en backlog garde sa priorité FIFO,
2. sinon la réservation avec le plus de passagers restants passe d'abord,
3. si une réservation est partiellement servie, elle reste prioritaire jusqu'à épuisement complet,
4. une réservation qui ne trouve aucune voiture ne bloque pas tout le groupe: elle passe seule en attente.

### 5. Choix du véhicule pour la réservation cible
Le véhicule est choisi selon cette hiérarchie:
1. nombre de trajets le plus faible,
2. meilleur fit sur le nombre de places,
3. diesel avant essence,
4. hasard uniquement en ultime égalité.

Point important:
- si aucune voiture ne peut servir entièrement la réservation cible, le fallback compare toujours les voitures par rapport au besoin réel de cette réservation,
- il ne réduit pas la demande à `1`.

### 6. Remplissage complémentaire
Après la réservation cible:
- la voiture est complétée avec d'autres réservations du même groupe,
- le remplissage complémentaire choisit la réservation la plus proche de la capacité restante,
- la réservation cible reste toujours prioritaire dans son tour.

### 7. Départ réel de la voiture
L'heure de départ réelle d'une voiture est calculée à partir de:
- la dernière arrivée parmi les passagers réellement embarqués dans cette voiture,
- la disponibilité réelle de la voiture (`depart_heure_disponibilite` ou `heureRetourAeroport`).

Donc:
- si la voiture est déjà disponible et que les passagers embarqués sont prêts, elle part immédiatement,
- elle n'attend pas la fin de la fenêtre globale du groupe.

### 8. Calcul du retour
- l'itinéraire est calculé après l'assignation,
- la durée du trajet est calculée,
- l'heure de retour runtime est mise à jour pour la voiture,
- cette heure sert ensuite à de futurs recomputes.

### 9. Recompute
Quand il reste des réservations en attente:
- le moteur cherche d'abord le prochain retour d'une voiture,
- s'il n'existe aucun retour runtime encore exploitable, il cherche la prochaine disponibilité statique des voitures,
- le recompute construit un nouveau groupe autour de cette heure,
- le backlog déjà présent garde sa priorité d'attente.

### 10. Fin de traitement
Si plus aucune voiture future n'est disponible:
- les passagers restants sont marqués comme non assignés.

## Ce qui ne doit plus arriver
- une réservation plus petite ne doit pas dépasser une réservation déjà en attente plus ancienne,
- une réservation partiellement servie ne doit pas perdre sa priorité entre deux voitures,
- une réservation ne doit pas bloquer tout le groupe si elle seule ne peut pas être servie,
- une voiture ne doit pas attendre la fin de la fenêtre du groupe si elle est déjà disponible et complètement remplie.

## Exemple de lecture fonctionnelle

### Cas 1 - Réservation cible trop grande pour une voiture
Si client A a 15 passagers et que les voitures disponibles sont de 12 et 13 places:
- la réservation cible reste client A,
- la voiture de 13 places est choisie avant celle de 12 places si les autres critères sont équivalents,
- le split est autorisé si besoin.

### Cas 2 - Réservations en attente multiples
Si client 2002 est déjà en attente avant client 2003:
- client 2002 reste devant client 2003 dans les recomputes,
- même si client 2003 est plus facile à servir,
- le backlog conserve l'ordre d'arrivée.

### Cas 3 - Voiture disponible dès maintenant
Si une voiture est disponible à 10:00 et que les passagers réellement embarqués sont prêts à 10:00:
- le départ est 10:00,
- pas 10:15,
- car l'heure de départ ne dépend plus d'une fenêtre globale artificielle.

## Résumé bref
La logique actuelle est un moteur d'assignation par groupes et backlog, avec:
- priorité au backlog,
- priorité à la réservation la plus lourde restante,
- split autorisé,
- best-fit véhicule par nombre de trajets / places / carburant,
- recompute sur retour ou disponibilité future,
- départ calculé sur les passagers réellement embarqués.
