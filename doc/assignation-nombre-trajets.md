# Module Assignation - Algorithme actuel et priorité par nombre de trajets

## Description

Ce document décrit l'algorithme actuel d'assignation des voitures aux réservations après refactorisation de `AssignationService.java`.

L'algorithme gère maintenant:
- le groupement par aéroport puis par fenêtre temporelle,
- la priorité entre réservations en attente,
- le split des passagers d'une réservation sur plusieurs voitures,
- la réutilisation des véhicules selon leur nombre de trajets,
- le meilleur choix de véhicule selon capacité, trajet, carburant et hasard,
- le recalcul quand une voiture redevient disponible.

---

## Règles de gestion actuelles

| # | Règle | Description |
|---|-------|-------------|
| RG-A1 | **Groupement par aéroport** | Les réservations sont d'abord regroupées par `idLieuAtterissage`. |
| RG-A2 | **Tri temporel** | Dans chaque aéroport, les réservations sont triées par heure d'arrivée croissante puis par identifiant. |
| RG-A3 | **Fenêtre initiale** | Le premier groupe est construit à partir d'une réservation ancre et d'une fenêtre de `TA` minutes autour de cette ancre. |
| RG-A4 | **Backlog prioritaire** | Les réservations déjà mises en attente restent prioritaires lors des recomputes, dans l'ordre d'arrivée en backlog. |
| RG-A5 | **Priorité de réservation** | Dans un groupe actif, la réservation avec le plus de passagers restants est prioritaire. En cas d'égalité, le meilleur fit véhicule sert de départage. |
| RG-A6 | **Réservation prioritaire conservée** | Une réservation partiellement servie garde la priorité jusqu'à ce que tous ses passagers restants soient assignés. |
| RG-A7 | **Pas de blocage de groupe** | Si la réservation courante n'a aucun véhicule disponible, seule cette réservation passe en attente; le reste du groupe continue à être traité. |
| RG-A8 | **Choix du véhicule** | Pour une réservation donnée, le véhicule est choisi selon: 1) nombre de trajets le plus faible, 2) écart de places le plus faible, 3) diesel avant essence, 4) hasard en ultime égalité. |
| RG-A9 | **Meilleur fit sur le vrai besoin** | Si aucune voiture ne peut couvrir complètement la réservation, le véhicule est quand même choisi en comparant sa capacité au nombre de passagers réels de la réservation, pas à `1`. |
| RG-A10 | **Split autorisé** | Une réservation peut être répartie sur plusieurs voitures si sa taille dépasse la capacité du véhicule ou si cela permet d'optimiser le remplissage. |
| RG-A11 | **Remplissage complémentaire** | Après la réservation cible, la voiture est complétée avec d'autres réservations du groupe via un best-fit sur la capacité restante. |
| RG-A12 | **Ordre du filler** | Le filler choisit la réservation la plus proche de la capacité restante, mais ne doit jamais passer devant la réservation cible prioritaire du tour. |
| RG-A13 | **Recompute backlog** | Quand il existe un backlog, le moteur cherche d'abord le prochain retour véhicule; s'il n'existe pas encore de retour, il se cale sur la prochaine disponibilité statique des voitures. |
| RG-A14 | **Heure de départ réelle** | L'heure de départ d'une voiture dépend de ses passagers réellement embarqués et de sa disponibilité réelle. Elle n'utilise plus la fin de la fenêtre du groupe par défaut. |
| RG-A15 | **Retour véhicule** | L'heure de retour est calculée après l'itinéraire et la durée de trajet, puis enregistrée comme heure de disponibilité runtime de la voiture. |
| RG-A16 | **Pas de groupe bloquant au dernier backlog** | Si plusieurs réservations sont en attente, l'algorithme ne réordonne pas le backlog par nombre de passagers au détriment de l'ordre d'attente. |

---

## Flux général

```
1. Charger les voitures et initialiser leurs compteurs runtime
   - nombreTrajets = 0
   - heureRetourAeroport = null

2. Charger les reservations du jour et les regrouper par aeroport d'atterrissage

3. Pour chaque aeroport:
   a. Trier les reservations par date d'arrivee croissante
   b. Construire un premier groupe autour d'une reservation ancre
   c. Tant qu'il reste des passagers a assigner:
      - choisir la reservation cible
      - choisir la meilleure voiture disponible
      - affecter la reservation cible
      - remplir la voiture avec d'autres reservations si possible
      - calculer depart, itineraire, duree et retour
      - incrementer le nombre de trajets de la voiture

4. Si une reservation ne peut pas etre servie maintenant:
   - elle passe en attente avec ses passagers restants
   - le moteur recompute quand une voiture redevient disponible

5. Si aucune voiture future n'est disponible:
   - les reservations restantes sont marquees non assignees
```

---

## Détail des méthodes helper

### `getAllVoitures()`
Récupère les voitures en base avec leurs attributs persistés:
- immatriculation,
- nombre de places,
- type de carburant,
- vitesse moyenne,
- temps d'attente,
- heure de disponibilité initiale.

Les champs runtime `nombreTrajets` et `heureRetourAeroport` sont ensuite initialisés en mémoire.

### `initialiserVoituresDisponibles()`
Prépare le stock runtime des voitures avant l'assignation:
- charge la liste des voitures,
- remet `nombreTrajets` à `0`,
- remet `heureRetourAeroport` à `null`.

### `regrouperReservationsParAeroport(List<Reservation>)`
Construit une map `aeroportId -> liste de reservations`.

Rôle:
- séparer les flux par aéroport d'atterrissage,
- garantir qu'un groupe ne mélange pas des destinations différentes.

### `trierReservationsParArrivee(List<Reservation>)`
Trie les réservations d'un aéroport:
- heure d'arrivée croissante,
- puis ID croissant si deux réservations ont la même heure.

Ce tri alimente le premier groupe et les recomputes.

### `extraireReservationPrioritaire(List<Reservation>, Map<Integer, ReservationEnAttente>)`
Extrait la prochaine réservation ancre:
- d'abord le premier élément du backlog s'il existe,
- sinon la première réservation restante triée par heure.

Rôle:
- préserver l'ordre d'attente,
- éviter qu'une réservation arrivée plus tard prenne la main sur une réservation déjà en attente.

### `construireGroupeFenetre(...)`
Construit le premier groupe autour d'une réservation ancre:
- prend la réservation principale,
- ajoute les réservations dans la fenêtre `TA` minutes autour de cette ancre,
- récupère les passagers restants si certaines réservations étaient déjà en backlog,
- trie le groupe pour que le backlog passe avant les nouvelles réservations.

Ce helper est utilisé pour le premier passage naturel d'un aéroport.

### `construireGroupeAutourDeRetour(...)`
Construit un groupe de recompute autour d'une heure de retour ou de disponibilité future:
- inclut toutes les réservations déjà en backlog,
- ajoute les réservations restantes dans la fenêtre `[retour - TA, retour + TA]`,
- retire ces réservations des listes de travail,
- conserve l'ordre d'attente du backlog.

Ce helper permet au moteur de relancer le calcul quand une voiture redevient disponible.

### `trierGroupeParPassagersRestants(...)`
Trie le groupe actif selon deux règles différentes:
- les réservations déjà en attente gardent leur ordre FIFO,
- les réservations fraîches sont ordonnées par nombre de passagers restants décroissant,
  puis par heure d'arrivée, puis par ID.

C'est la clé pour éviter qu'une réservation plus récente ou plus petite dépasse une réservation déjà en attente.

### `positionDansEnAttente(...)`
Donne la position d'une réservation dans le backlog courant.

Rôle:
- implémenter un tri FIFO stable pour les réservations en attente,
- empêcher le backlog d'être reclassé par taille de groupe.

### `trouverReservationCibleInitiale(...)`
Choisit la première réservation cible d'un groupe:
- d'abord une réservation issue du backlog présent dans le groupe,
- sinon la première réservation restante.

Rôle:
- donner la priorité au backlog dès l'entrée dans un groupe,
- respecter la continuité d'une réservation déjà partiellement servie.

### `trouverReservationCibleMeilleurFit(...)`
Choisit la réservation cible pour les tours suivants dans le groupe:
- priorité au plus grand nombre de passagers restants,
- en cas d'égalité, la réservation qui produit le meilleur fit avec une voiture disponible,
- puis l'ID le plus faible si nécessaire.

Important:
- cette méthode ne doit pas faire passer une petite réservation devant une grande juste parce qu'elle est plus facile à caser.

### `trouverMeilleureVoitureDisponible(...)`
Sélectionne la voiture qui peut servir complètement la réservation cible.

Priorités appliquées:
1. le plus petit nombre de trajets,
2. le plus petit écart de places,
3. diesel avant essence,
4. hasard uniquement si tout est encore à égalité.

Cette méthode est utilisée quand on veut servir entièrement la réservation cible.

### `trouverMeilleureVoiturePourCible(...)`
Sélectionne la meilleure voiture même si la réservation cible ne peut pas être servie en totalité.

Elle applique les mêmes priorités que le sélecteur principal, mais compare toujours la capacité à la taille réelle de la réservation cible.

Rôle:
- éviter que le fallback réduise artificiellement la réservation à une demande de `1` passager,
- conserver le vrai best-fit sur la réservation cible.

### `assignerReservationCible(...)`
Ajoute la réservation cible à l'assignation:
- assigne tout si un full fit est possible,
- sinon assigne seulement ce qui rentre,
- met à jour le nombre de passagers restants,
- trace si l'assignation est partielle ou complète.

### `remplirVoitureAvecAutresReservations(...)`
Complète la voiture avec d'autres réservations du groupe après la cible principale.

Le but est de maximiser le remplissage sans casser la priorité de la réservation cible.

### `trouverMeilleureReservationPourCapacite(...)`
Choisit la meilleure réservation pour remplir les places restantes d'une voiture:
- meilleur écart absolu avec la capacité restante,
- puis le plus grand nombre de passagers restants,
- puis l'ID le plus faible.

Rôle:
- faire du vrai best-fit de remplissage,
- éviter de gaspiller des places.

### `calculerHeureDepart(AssignationVoiture, Voiture)`
Calcule l'heure de départ réelle à partir:
- de la dernière arrivée parmi les réservations réellement embarquées,
- et de la disponibilité actuelle de la voiture.

Règle:
- le départ est le maximum entre l'heure des passagers réellement servis et la disponibilité de la voiture.

### `trouverHeureDisponibiliteCourante(Voiture)`
Retourne la disponibilité runtime effective de la voiture:
- heure de disponibilité initiale,
- ou heure de retour si la voiture a déjà roulé et que ce retour est plus tardif.

### `finaliserAssignation(...)`
Termine le traitement d'une voiture:
- fixe l'assignation,
- calcule l'itinéraire,
- calcule la durée,
- enregistre l'heure de retour runtime,
- trace le départ et le retour.

### `trouverProchaineHeureRetourVoitureApres(...)`
Cherche le prochain retour de voiture après une borne donnée.

Utilité:
- alimenter le recompute quand un backlog existe et qu'une voiture revient.

### `trouverProchaineHeureDisponibiliteVoitureApres(...)`
Cherche la prochaine disponibilité future en tenant compte:
- de l'heure de disponibilité initiale,
- de l'heure de retour runtime si elle est plus tardive.

Utilité:
- éviter le blocage quand il n'existe encore aucun retour runtime,
- permettre au backlog d'attendre la prochaine voiture réellement utilisable.

### `marquerPassagersNonAssignes(...)`
Marque les passagers encore non servis quand il n'existe plus aucune solution future.

Rôle:
- produire le résultat final visible côté interface,
- ne pas confondre un simple report avec un échec définitif.

---

## Points importants de comportement

### 1. Le backlog ne doit pas être reclassé par taille
Une réservation déjà en attente reste prioritaire sur une réservation arrivée plus tard, même si cette dernière a plus de passagers ou un meilleur fit.

### 2. Une réservation partiellement servie garde la main
Si une réservation a été coupée entre plusieurs voitures, la partie restante doit continuer à être servie avant de laisser passer une autre réservation du même groupe.

### 3. Le choix de voiture reste indépendant de la priorité de réservation
La priorité de réservation détermine **quelle réservation** est servie.
La priorité de voiture détermine **quel véhicule** est utilisé pour cette réservation.

### 4. Le départ dépend des passagers réellement embarqués
Le départ n'est plus basé sur la fin de la fenêtre du groupe, mais sur:
- les réservations réellement embarquées,
- la disponibilité effective du véhicule.

---

## Exemples de lecture des logs

### Log `[Wait]`
Une réservation cible n'a pas trouvé de véhicule disponible maintenant.

Effet:
- seule cette réservation passe en attente,
- le groupe continue,
- un recompute sera tenté plus tard.

### Log `[Recompute] Aucun retour en cours; prochaine disponibilite ...`
Le backlog existe, mais aucun véhicule n'a encore de retour runtime exploitable.

Effet:
- le moteur se cale sur la prochaine disponibilité statique d'une voiture.

### Log `[Assignation partielle]`
La voiture n'a pas assez de places pour couvrir la réservation cible en totalité.

Effet:
- le reste de la réservation est conservé en backlog avec priorité.

### Log `[Trajet] ... Départ: ... - Retour prévu: ...`
Le départ réel et le retour runtime de la voiture ont été calculés et enregistrés.

---

## Résumé

L'algorithme actuel n'est plus un simple tri glouton par capacité. C'est un moteur de planification avec:
- priorité backlog,
- priorité par volume de passagers restants,
- split de réservation,
- best-fit véhicule,
- recompute sur retour ou disponibilité future,
- départ calculé sur les passagers réellement embarqués.
├── Toutes les voitures: trajets=0, heureRetour=null

Après chaque assignation
├── voiture.trajets++
└── voiture.heureRetour = heureDepart + tempsTrajet
```

---

## Données de test

Script: `database-scripts/03-17_test_nombre_trajets.sql`

| Scénario | Réservation | Heure | Passagers | Voiture attendue | Raison |
|----------|-------------|-------|-----------|------------------|--------|
| 1 | R1 | 04:00 | 3 | TEST-D5 | Diesel prioritaire (0 trajet) |
| 1 | R2 | 05:30 | 3 | TEST-E5 | 0 trajet vs 1 trajet (TEST-D5) |
| 1 | R3 | 07:00 | 3 | TEST-D5 | Égalité trajets, diesel prioritaire |
| 2 | R4 | 04:30 | 4 | TEST-E5 | TEST-D5 en trajet |
| 3 | R5 | 08:00 | 28 | TEST-E30 | Seule avec capacité 30 |
| 4 | R6 | 05:00 | 28 | TEST-E30 | Départ retardé au retour de V |
| 5 | R7-R9 | 10:00-10:25 | 5 | Regroupées | Fenêtre TA = 30 min |
| 6 | R11 | 12:00 | 28 | TEST-E30 | Prend la voiture |
| 6 | R12 | 12:05 | 28 | Reportée → R13 | Pas de groupe spécial à 13:30 |
| 6 | R12+R13 | 15:00 | 30 | TEST-E30 | Prochain groupe naturel |

---

## Fichiers modifiés

| Fichier | Modifications |
|---------|--------------|
| `Voiture.java` | Ajout `nombreTrajets`, `heureRetourAeroport`, `estDisponibleA()` |
| `AssignationService.java` | Nouvelle logique de sélection avec priorité trajets |
| `03-17_test_nombre_trajets.sql` | Script de test des nouvelles règles |

---

## Résumé

La méthode `assignerVoitures` assure maintenant une **répartition équitable** des trajets entre les voitures tout en respectant la **disponibilité temporelle**. Les voitures qui ont moins travaillé sont prioritaires, et les clients sont servis dès qu'une voiture adaptée devient disponible, même si cela implique un délai d'attente.
