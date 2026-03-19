# Module Assignation - Priorité par Nombre de Trajets (Sprint 6)

## Description

Ce module étend la logique d'assignation des voitures aux réservations en ajoutant la **priorité par nombre de trajets**. L'objectif est de répartir équitablement les trajets entre les voitures disponibles et de gérer la **disponibilité temporelle** des voitures en fonction de leur heure de retour à l'aéroport.

---

## Règles de gestion

| # | Règle | Description |
|---|-------|-------------|
| RG-T1 | **Priorité nombre de trajets** | La voiture ayant effectué le **moins de trajets** dans la journée est prioritaire pour une nouvelle assignation. |
| RG-T2 | **Voiture en trajet = non disponible** | Une voiture partie en trajet n'est plus candidate jusqu'à son **retour à l'aéroport**. |
| RG-T3 | **Heure de retour** | L'heure de retour est calculée : `heureDepart + tempsTrajet`. La voiture devient disponible à partir de cette heure. |
| RG-T4 | **Heure de départ ajustée** | Si la meilleure voiture revient **après** l'heure d'arrivée du client, le départ est retardé à l'heure de retour de la voiture. |
| RG-T5 | **Report au prochain groupe** | Une réservation non assignée (pas de voiture disponible) est **reportée au prochain groupe** de réservations, pas à l'heure de retour de la voiture. |
| RG-T6 | **Critères de sélection (ordre)** | 1. Nombre de trajets le plus bas → 2. Écart de places minimum → 3. Diesel prioritaire → 4. ID le plus bas (déterministe). |
| RG-T7 | **Trajet = aller-retour complet** | Un trajet comprend : Aéroport → Hôtel(s) → Retour Aéroport. La voiture reste indisponible pendant toute cette durée. |
| RG-T8 | **Hypothèse initiale** | À 00:00:00, toutes les voitures sont supposées à l'aéroport et disponibles (0 trajet effectué). |
| RG-T9 | **Pas de groupe spécial** | Une réservation non assignée ne crée **pas de groupe spécial** à l'heure de retour de la voiture ; elle attend le prochain groupe naturel. |

---

## Flux de fonctionnement

```
1. Charger toutes les voitures (trajets = 0, disponibles à 00:00)
2. Pour chaque groupe de réservations (même aéroport, triées par heure):
   │
   ├── Calculer le total de passagers et la fenêtre de temps [heure, heure + TA]
   │
   ├── Chercher la meilleure voiture DISPONIBLE:
   │   ├── Capacité suffisante
   │   ├── heureRetour <= heureDepart souhaitée
   │   └── Priorité: moins de trajets > fit optimal > diesel
   │
   ├── Si TROUVÉE:
   │   ├── Calculer heureDepart = max(heureArriveeClient, heureRetourVoiture)
   │   ├── Calculer itinéraire et heureRetour
   │   ├── Mettre à jour: voiture.trajets++, voiture.heureRetour
   │   ├── Les réservations qui ne rentrent pas → reportées au prochain groupe
   │   └── Créer l'assignation
   │
   └── Si NON TROUVÉE et qu'il y a d'autres réservations après:
       └── Reporter TOUT le groupe au prochain groupe naturel
           (pas de groupe spécial à l'heure de retour)

3. Si c'est le dernier groupe et aucune voiture disponible:
   └── Attendre la prochaine voiture qui sera disponible
```

---

## Extraits de code

### Entité `Voiture.java` — Champs de suivi des trajets

```java
// Champs runtime pour le suivi des trajets (non persistés en BDD)
private int nombreTrajets = 0;
private java.sql.Timestamp heureRetourAeroport = null; // null = disponible dès 00:00

public int getNombreTrajets() {
    return nombreTrajets;
}

public void incrementerTrajets() {
    this.nombreTrajets++;
}

public java.sql.Timestamp getHeureRetourAeroport() {
    return heureRetourAeroport;
}

public void setHeureRetourAeroport(java.sql.Timestamp heureRetourAeroport) {
    this.heureRetourAeroport = heureRetourAeroport;
}

/**
 * Vérifie si la voiture est disponible à une heure donnée.
 */
public boolean estDisponibleA(java.sql.Timestamp heure) {
    if (heureRetourAeroport == null) {
        return true; // Disponible dès le début
    }
    return heure != null && !heure.before(heureRetourAeroport);
}
```

### Service `AssignationService.java` — Sélection de la meilleure voiture

```java
/**
 * Trouve la meilleure voiture disponible selon les règles:
 * 1. Capacité suffisante
 * 2. Disponible à l'heure demandée
 * 3. Priorité: moins de trajets > moins d'écart de places > diesel > ID
 */
private Voiture trouverMeilleureVoitureDisponible(int nombrePassagers, Timestamp heureDepart) {
    List<Voiture> candidates = new ArrayList<>();

    for (Voiture v : voituresDisponibles) {
        if (v.getNombrePlaces() >= nombrePassagers && v.estDisponibleA(heureDepart)) {
            candidates.add(v);
        }
    }

    if (candidates.isEmpty()) {
        return null;
    }

    // Trier selon les critères de priorité
    candidates.sort(new Comparator<Voiture>() {
        @Override
        public int compare(Voiture a, Voiture b) {
            // 1. Nombre de trajets (moins = mieux)
            int cmpTrajets = Integer.compare(a.getNombreTrajets(), b.getNombreTrajets());
            if (cmpTrajets != 0) return cmpTrajets;

            // 2. Écart de places (moins = mieux)
            int ecartA = a.getNombrePlaces() - nombrePassagers;
            int ecartB = b.getNombrePlaces() - nombrePassagers;
            int cmpEcart = Integer.compare(ecartA, ecartB);
            if (cmpEcart != 0) return cmpEcart;

            // 3. Diesel préféré
            boolean aDiesel = "D".equals(a.getTypeCarburant());
            boolean bDiesel = "D".equals(b.getTypeCarburant());
            if (aDiesel && !bDiesel) return -1;
            if (!aDiesel && bDiesel) return 1;

            // 4. ID comme tie-breaker
            return Integer.compare(a.getId(), b.getId());
        }
    });

    return candidates.get(0);
}
```

### Service `AssignationService.java` — Calcul de l'heure de départ

```java
// Calculer l'heure de départ = max(heureArriveeMax, heureRetourVoiture)
Timestamp heureDepart = heureArriveeMax;
if (bestVoiture.getHeureRetourAeroport() != null && heureArriveeMax != null) {
    if (bestVoiture.getHeureRetourAeroport().after(heureArriveeMax)) {
        heureDepart = bestVoiture.getHeureRetourAeroport();
    }
}

// Mettre à jour l'heure de retour de la voiture après le trajet
if (assignation.getHeureRetourAeroport() != null && heureDepart != null) {
    String heureRetourStr = heureDepart.toString().substring(0, 11)
        + assignation.getHeureRetourAeroport() + ":00";
    Timestamp heureRetour = Timestamp.valueOf(heureRetourStr);
    bestVoiture.setHeureRetourAeroport(heureRetour);
}

// Incrémenter le compteur de trajets
bestVoiture.incrementerTrajets();
```

---

## Exemples de scénarios

### Exemple 1 — Priorité par nombre de trajets

**Données:**
- Voiture V1 (diesel, 5 places): 0 trajet
- Voiture V2 (essence, 5 places): 0 trajet
- Réservation R1: 04:00, 3 passagers

**Résultat:**
- R1 → **V1** (diesel prioritaire car égalité de trajets)
- V1.trajets = 1, V1.heureRetour = ~05:00

**Suite:**
- Réservation R2: 05:30, 3 passagers
- V1 a fait 1 trajet, V2 a fait 0 trajet
- R2 → **V2** (moins de trajets que V1)

### Exemple 2 — Voiture indisponible temporairement

**Données:**
- V1 (30 places) part à 04:30, retour prévu 05:30
- Client arrive à 05:00 avec 28 passagers

**Résultat:**
- Aucune autre voiture ne peut prendre 28 passagers
- Attendre V1 qui revient à 05:30
- Départ du client = **05:30** (pas 05:00)

```
Timeline:
04:30 ─────────── V1 en trajet ──────────── 05:30
        05:00                                 ↓
        Client arrive                    V1 disponible
        (attend)                         Départ client
```

### Exemple 3 — Report au prochain groupe (RG-T9)

**Données:**
- V1 (30 places, seule capable) part à 04:00, retour prévu 05:00
- R1: 04:30, 28 passagers (aucune voiture disponible à 04:30)
- R2: 10:30, 2 passagers (prochaine réservation)

**Comportement INCORRECT (ancien):**
- R1 crée un groupe spécial à 05:00 (heure retour V1)
- Départ de R1 = 05:00

**Comportement CORRECT (nouveau):**
- R1 n'a pas de voiture disponible à 04:30
- R1 est **reportée au prochain groupe** (celui de 10:30)
- R1 et R2 sont regroupées ensemble
- Départ = 10:30 (pas 05:00)

```
Timeline:
04:00 ──── V1 en trajet ──── 05:00     10:30
  │                            │          │
04:30                       V1 revient   R1 + R2
R1 arrive                   (non utilisé  regroupées
(pas de voiture)             à 05:00)    → Départ
```

**Raison:** On ne crée pas de groupe spécial à l'heure de retour de la voiture. La réservation attend le prochain groupe naturel de réservations.

### Exemple 4 — Répartition équitable

**Données (fin de journée):**
- V1: 3 trajets effectués
- V2: 2 trajets effectués
- V3: 4 trajets effectués
- Nouvelle réservation: 3 passagers

**Résultat:**
- **V2** est sélectionnée (2 trajets, le minimum)
- Même si V1 est diesel et V2 essence, le nombre de trajets prime

---

## Modèle de données

### Champs runtime (en mémoire, non persistés)

```
Voiture
├── nombreTrajets (int, default 0)      -- Compteur de trajets du jour
├── heureRetourAeroport (Timestamp)     -- Heure de disponibilité
└── estDisponibleA(heure) (méthode)     -- Vérifie la disponibilité
```

### Flux de mise à jour

```
Initialisation (00:00)
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
