package org.itu.util;

import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ThreadLocalRandom;

import org.itu.entity.AssignationVoiture;
import org.itu.entity.Distance;
import org.itu.entity.Lieu;
import org.itu.entity.Reservation;
import org.itu.entity.Voiture;

/**
 * Service pour assigner les voitures aux réservations selon les règles:
 * 1. Regrouper par aéroport puis par fenêtre d'arrivée
 * 2. Trier les réservations par heure d'arrivée puis par nombre de passagers décroissant dans chaque groupe
 * 3. Remplir les voitures une par une en autorisant la séparation des passagers d'un même client
 * 4. Sélectionner la voiture selon la priorité: moins de trajets, meilleur fit, diesel, puis hasard en ultime égalité
 * 5. Une voiture est disponible si son heure de retour est <= l'heure de départ souhaitée
 * 6. L'heure de départ = max(heure d'arrivée du dernier passager, heure retour de la voiture)
 */
public class AssignationService {
    private final DB db;
    private List<Voiture> voituresDisponibles;

    public AssignationService(DB db) {
        this.db = db;
        this.voituresDisponibles = new ArrayList<>();
    }

    /**
     * Récupère toutes les distances entre les lieux
     */
    public List<Distance> getAllDistances() {
        List<Distance> distances = new ArrayList<>();
        String sql = "SELECT d.id, d.lieu_from, d.lieu_to, d.km, " +
                     "lf.id as lf_id, lf.code as lf_code, lf.libelle as lf_libelle, lf.type_lieu as lf_type, " +
                     "lt.id as lt_id, lt.code as lt_code, lt.libelle as lt_libelle, lt.type_lieu as lt_type " +
                     "FROM distance d " +
                     "JOIN lieu lf ON d.lieu_from = lf.id " +
                     "JOIN lieu lt ON d.lieu_to = lt.id";
        try (java.sql.Statement stmt = db.getConnection().createStatement();
                ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                Lieu fromLieu = new Lieu(rs.getInt("lf_id"), rs.getString("lf_code"), rs.getString("lf_libelle"), rs.getString("lf_type"));
                Lieu toLieu = new Lieu(rs.getInt("lt_id"), rs.getString("lt_code"), rs.getString("lt_libelle"), rs.getString("lt_type"));
                Distance d = new Distance(rs.getInt("id"), fromLieu, toLieu, rs.getDouble("km"));
                distances.add(d);
            }
        } catch (SQLException e) {
            System.out.println("Erreur lors de la récupération des distances : " + e.getMessage());
        }
        return distances;
    }

    /**
     * Récupère le temps d'attente global en minutes depuis la table parametre (libelle = 'temps_attente' ou code = 'TA')
     */
    public double getTempsAttenteMinutes() {
        String sql = "SELECT valeur FROM parametre WHERE LOWER(libelle) IN ('temps_attente', 'ta') LIMIT 1";
        try (java.sql.Statement stmt = db.getConnection().createStatement();
                ResultSet rs = stmt.executeQuery(sql)) {
            if (rs.next()) {
                String val = rs.getString("valeur").replaceAll("[^0-9.]", "");
                return Double.parseDouble(val);
            }
        } catch (SQLException e) {
            System.out.println("Erreur lors de la récupération du temps d'attente : " + e.getMessage());
        }
        return 30.0; // valeur par défaut: 30 minutes
    }

    /**
     * Récupère le lieu de type AEROPORT
     */
    public Lieu getAeroport() {
        String sql = "SELECT l.id, l.code, l.libelle, l.type_lieu FROM lieu l " +
                     "JOIN type_lieu tl ON CAST(l.type_lieu AS INTEGER) = tl.id " +
                     "WHERE tl.libelle = 'AEROPORT' ORDER BY l.id ASC LIMIT 1";
        try (java.sql.Statement stmt = db.getConnection().createStatement();
                ResultSet rs = stmt.executeQuery(sql)) {
            if (rs.next()) {
                return new Lieu(rs.getInt("id"), rs.getString("code"), rs.getString("libelle"), rs.getString("type_lieu"));
            }
        } catch (SQLException e) {
            System.out.println("Erreur lors de la récupération de l'aéroport : " + e.getMessage());
        }
        return null;
    }

    /**
     * Récupère la vitesse en km/h depuis la table parametre (libelle = 'vitesse')
     */
    public double getVitesseKmH() {
        String sql = "SELECT valeur FROM parametre WHERE LOWER(libelle) = 'vitesse' LIMIT 1";
        try (java.sql.Statement stmt = db.getConnection().createStatement();
                ResultSet rs = stmt.executeQuery(sql)) {
            if (rs.next()) {
                String val = rs.getString("valeur").replaceAll("[^0-9.]", "");
                return Double.parseDouble(val);
            }
        } catch (SQLException e) {
            System.out.println("Erreur lors de la récupération de la vitesse : " + e.getMessage());
        }
        return 30.0; // valeur par défaut
    }

    /**
     * Trouve la distance entre deux lieux (dans les deux sens)
     */
    private Double findDistance(List<Distance> distances, int fromId, int toId) {
        for (Distance d : distances) {
            if ((d.getFromLieuId() == fromId && d.getToLieuId() == toId) ||
                (d.getFromLieuId() == toId && d.getToLieuId() == fromId)) {
                return d.getKm();
            }
        }
        return null;
    }

    /**
     * Calcule l'itinéraire optimal (plus proche voisin) et l'heure de retour à l'aéroport.
     * Trajet: Aéroport → hotel le plus proche → ... → Aéroport (aller-retour complet).
     *
     * Vitesse utilisée : voiture.vitesseMoyenne en priorité, sinon defaultVitesseKmH (table parametre).
     * Temps total = (distanceTotale / vitesse × 60) + (nbArrêts × tempAttente de la voiture).
     */
    private void computeItineraire(AssignationVoiture assignation, Lieu aeroport, List<Distance> distances, double defaultVitesseKmH) {
        if (aeroport == null || assignation.getLieux() == null || assignation.getLieux().isEmpty()) {
            return;
        }

        // --- Vitesse : voiture.vitesseMoyenne > table parametre > 30 km/h ---
        double vitesseKmH = defaultVitesseKmH;
        Voiture voiture = assignation.getVoiture();
        if (voiture != null && voiture.getVitesseMoyenne() != null
                && voiture.getVitesseMoyenne().doubleValue() > 0) {
            vitesseKmH = voiture.getVitesseMoyenne().doubleValue();
        }

        assignation.setVitesseKmH(vitesseKmH);

        // --- Collecter les lieux uniques à visiter (hors aéroport) ---
        List<Lieu> hotelsToVisit = new ArrayList<>();
        List<Integer> seenIds = new ArrayList<>();
        for (Lieu l : assignation.getLieux()) {
            if (l.getId() != null && !seenIds.contains(l.getId()) && !l.getId().equals(aeroport.getId())) {
                hotelsToVisit.add(l);
                seenIds.add(l.getId());
            }
        }

        if (hotelsToVisit.isEmpty()) {
            return;
        }

        // --- Algorithme du plus proche voisin ---
        List<Lieu> itineraire = new ArrayList<>();
        List<Double> distancesParEtape = new ArrayList<>();
        itineraire.add(aeroport);
        double totalKm = 0;
        int currentId = aeroport.getId();

        while (!hotelsToVisit.isEmpty()) {
            Lieu closest = null;
            double minDist = Double.MAX_VALUE;
            int closestIndex = -1;

            for (int i = 0; i < hotelsToVisit.size(); i++) {
                Lieu hotel = hotelsToVisit.get(i);
                Double dist = findDistance(distances, currentId, hotel.getId());
                if (dist != null) {
                    if (dist < minDist ||
                        (dist == minDist && closest != null &&
                         hotel.getLibelle().compareToIgnoreCase(closest.getLibelle()) < 0)) {
                        minDist = dist;
                        closest = hotel;
                        closestIndex = i;
                    }
                }
            }

            if (closest == null) {
                // Pas de distance connue : ajouter les restants sans distance
                for (Lieu remaining : hotelsToVisit) {
                    itineraire.add(remaining);
                    distancesParEtape.add(null);
                }
                hotelsToVisit.clear();
                break;
            }

            itineraire.add(closest);
            distancesParEtape.add(minDist);
            totalKm += minDist;
            currentId = closest.getId();
            hotelsToVisit.remove(closestIndex);
        }

        // --- Retour à l'aéroport ---
        Double retourDist = findDistance(distances, currentId, aeroport.getId());
        if (retourDist != null) {
            totalKm += retourDist;
        }
        distancesParEtape.add(retourDist); // dernier tronçon : dernier hotel → aéroport
        itineraire.add(aeroport);

        assignation.setItineraire(itineraire);
        assignation.setDistancesParEtape(distancesParEtape);
        assignation.setDistanceTotaleKm(Math.round(totalKm * 100.0) / 100.0);

        // --- Calcul du temps de trajet (conduite seule) ---
        double tempsConduiteMin = (vitesseKmH > 0) ? (totalKm / vitesseKmH * 60.0) : 0;
        assignation.setTempsTrajetMinutes(Math.round(tempsConduiteMin));

        System.out.printf("[Itinéraire] Voiture %s | %.2f km | %.0f km/h | %.0f min%n",
            voiture != null ? voiture.getMatricule() : "?",
            totalKm, vitesseKmH, tempsConduiteMin);

        // --- Heure de retour = heure de départ + temps de conduite (arrondi) ---
        if (vitesseKmH > 0 && assignation.getReservation() != null) {
            String dateStr = assignation.getReservation().getDateArriver();
            if (dateStr != null) {
                try {
                    java.sql.Timestamp depart = java.sql.Timestamp.valueOf(dateStr);
                    long millis = assignation.getTempsTrajetMinutes() * 60 * 1000;
                    java.sql.Timestamp retour = new java.sql.Timestamp(depart.getTime() + millis);
                    assignation.setHeureRetourAeroport(retour.toString().substring(11, 16));
                } catch (Exception e) {
                    System.out.println("Erreur calcul heure retour: " + e.getMessage());
                }
            }
        }
    }

    /**
     * Récupère toutes les voitures disponibles
     */
    public List<Voiture> getAllVoitures() {
        List<Voiture> voitures = new ArrayList<>();
        String sql = "SELECT id, matricule, marque, model, nombre_place, type_carburant, vitesse_moyenne, temp_attente, depart_heure_disponibilite FROM voiture ORDER BY nombre_place, type_carburant";
        try (java.sql.Statement stmt = db.getConnection().createStatement();
                ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                Voiture v = new Voiture(
                    rs.getInt("id"),
                    rs.getString("matricule"),
                    rs.getString("marque"),
                    rs.getString("model"),
                    rs.getInt("nombre_place"),
                    rs.getString("type_carburant"),
                    rs.getBigDecimal("vitesse_moyenne"),
                    rs.getBigDecimal("temp_attente"),
                    rs.getTimestamp("depart_heure_disponibilite")
                );
                voitures.add(v);
            }
        } catch (SQLException e) {
            System.out.println("Erreur lors de la récupération des voitures : " + e.getMessage());
        }
        return voitures;
    }

    /**
     * Récupère les réservations pour une date donnée
     */
    public List<Reservation> getReservationsByDate(Date date) {
        List<Reservation> reservations = new ArrayList<>();
        String sql = "SELECT r.*, l.id as lieu_id, l.code, l.libelle, l.type_lieu, " +
                     "la.id as aero_id, la.code as aero_code, la.libelle as aero_libelle, la.type_lieu as aero_type " +
                     "FROM reservation r " +
                     "JOIN lieu l ON r.idlieu = l.id " +
                     "LEFT JOIN lieu la ON r.idlieuatterissage = la.id " +
                     "WHERE DATE(r.datearrivee) = ? " +
                     "ORDER BY r.datearrivee";
        try (PreparedStatement stmt = db.getConnection().prepareStatement(sql)) {
            stmt.setDate(1, date);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Lieu lieu = new Lieu(
                        rs.getInt("lieu_id"),
                        rs.getString("code"),
                        rs.getString("libelle"),
                        rs.getString("type_lieu")
                    );
                    Lieu aero = null;
                    if (rs.getObject("aero_id") != null) {
                        aero = new Lieu(rs.getInt("aero_id"), rs.getString("aero_code"),
                                        rs.getString("aero_libelle"), rs.getString("aero_type"));
                    }
                    Reservation r = new Reservation(
                        rs.getInt("id"),
                        rs.getInt("idclient"),
                        rs.getTimestamp("datearrivee"),
                        rs.getInt("nombrepassagers"),
                        lieu,
                        aero
                    );
                    reservations.add(r);
                }
            }
        } catch (SQLException e) {
            System.out.println("Erreur lors de la récupération des réservations : " + e.getMessage());
        }
        return reservations;
    }

    /**
     * Assigne les voitures aux réservations pour une date donnée.
     * Nouvelles règles Sprint 7:
     * 1. Sous-grouper par aéroport (lieu d'atterrissage)
     * 2. Trier par heure d'arrivée chronologique
     * 3. Pour chaque groupe, remplir les voitures une par une:
     *    - Trier les réservations par nombre de passagers décroissant
     *    - Les passagers d'un même client peuvent être séparés entre plusieurs voitures
     *    - Pour chaque voiture, remplir avec le maximum de passagers possible
     * 4. Priorité de sélection de voiture:
     *    - Priorité 1: Nombre de trajets le plus bas
     *    - Priorité 2: Meilleur fit (moins d'écart de places)
     *    - Priorité 3: Diesel préféré
     *    - Priorité 4: Random si égalité
     * 5. Une voiture est disponible si son heure de retour <= heure de départ souhaitée
     * 6. Heure de départ = max(heure arrivée dernier passager, heure retour voiture)
     * 7. Un client est non assignable SEULEMENT si le total de ses passagers > capacité TOTALE de toutes les voitures
     * 8. Les passagers d'un même client peuvent être séparés entre plusieurs voitures
     */
    public List<AssignationVoiture> assignerVoitures(Date date) {
        List<AssignationVoiture> assignations = new ArrayList<>();

        initialiserVoituresDisponibles();

        List<Reservation> reservations = getReservationsByDate(date);
        double tempsAttente = getTempsAttenteMinutes();
        Lieu aeroportGlobal = getAeroport();
        List<Distance> allDistances = getAllDistances();
        double vitesse = getVitesseKmH();

        Map<Integer, List<Reservation>> airportGroups = regrouperReservationsParAeroport(reservations);
        for (List<Reservation> airportReservations : airportGroups.values()) {
            traiterGroupeAeroport(airportReservations, tempsAttente, aeroportGlobal, allDistances, vitesse, assignations);
        }

        return assignations;
    }

    private void initialiserVoituresDisponibles() {
        voituresDisponibles = getAllVoitures();
        for (Voiture voiture : voituresDisponibles) {
            voiture.setNombreTrajets(0);
            voiture.setHeureRetourAeroport(null);
        }
    }

    private Map<Integer, List<Reservation>> regrouperReservationsParAeroport(List<Reservation> reservations) {
        Map<Integer, List<Reservation>> airportGroups = new LinkedHashMap<>();
        for (Reservation reservation : reservations) {
            Integer aeroId = reservation.getLieuAtterissage() != null ? reservation.getLieuAtterissage().getId() : null;
            int airportKey = 0;
            if (aeroId != null) {
                airportKey = Integer.parseInt(aeroId.toString());
            }
            airportGroups.computeIfAbsent(airportKey, key -> new ArrayList<>()).add(reservation);
        }
        return airportGroups;
    }

    private void traiterGroupeAeroport(List<Reservation> airportReservations, double tempsAttente,
            Lieu aeroportGlobal, List<Distance> allDistances, double vitesse, List<AssignationVoiture> assignations) {
        trierReservationsParArrivee(airportReservations);

        List<Reservation> remaining = new ArrayList<>(airportReservations);
        while (!remaining.isEmpty()) {
            Reservation mainReservation = remaining.remove(0);
            List<Reservation> groupe = construireGroupeFenetre(mainReservation, remaining, tempsAttente);
            Timestamp heureArriveeMax = trouverHeureArriveeMax(groupe);
            Map<Integer, Integer> passagersRestants = initialiserPassagersRestants(groupe);

            while (hasPassagersRestants(passagersRestants)) {
                Reservation cible = trouverReservationCible(groupe, passagersRestants);
                if (cible == null) {
                    break;
                }

                int passagersCible = passagersRestants.get(cible.getId());
                Voiture bestVoiture = trouverMeilleureVoitureDisponible(passagersCible, heureArriveeMax, null);
                boolean cibleFullFitPossible = bestVoiture != null;

                if (!cibleFullFitPossible) {
                    bestVoiture = trouverMeilleureVoitureDisponible(1, heureArriveeMax, null);
                }

                if (bestVoiture == null) {
                    bestVoiture = trouverProchaineVoitureDisponible(1);
                }

                if (bestVoiture == null) {
                    marquerPassagersNonAssignes(assignations, groupe, passagersRestants);
                    break;
                }

                Timestamp heureDepart = calculerHeureDepart(heureArriveeMax, bestVoiture);
                AssignationVoiture assignation = new AssignationVoiture();
                assignation.setVoiture(bestVoiture);

                int capaciteRestante = bestVoiture.getNombrePlaces();
                capaciteRestante = assignerReservationCible(assignation, cible, passagersRestants, passagersCible,
                        capaciteRestante, cibleFullFitPossible, bestVoiture);
                remplirVoitureAvecAutresReservations(assignation, groupe, passagersRestants,
                    cible, capaciteRestante, heureArriveeMax, bestVoiture);

                finaliserAssignation(assignation, bestVoiture, cible, heureDepart, aeroportGlobal, allDistances, vitesse);
                bestVoiture.incrementerTrajets();
                System.out.printf("[Statistiques] Voiture %s a maintenant fait %d trajet(s)%n",
                        bestVoiture.getMatricule(), bestVoiture.getNombreTrajets());

                assignations.add(assignation);
            }
        }
    }

    private void trierReservationsParArrivee(List<Reservation> reservations) {
        reservations.sort((a, b) -> {
            Timestamp ta = a.getDateArriverAsTimestamp();
            Timestamp tb = b.getDateArriverAsTimestamp();
            if (ta == null && tb == null) {
                return Integer.compare(a.getId(), b.getId());
            }
            if (ta == null) {
                return 1;
            }
            if (tb == null) {
                return -1;
            }
            int cmp = ta.compareTo(tb);
            if (cmp != 0) {
                return cmp;
            }
            return Integer.compare(a.getId(), b.getId());
        });
    }

    private List<Reservation> construireGroupeFenetre(Reservation mainReservation, List<Reservation> remaining,
            double tempsAttente) {
        List<Reservation> groupe = new ArrayList<>();
        groupe.add(mainReservation);

        Timestamp mainTime = mainReservation.getDateArriverAsTimestamp();
        Timestamp finFenetre = null;
        if (mainTime != null) {
            finFenetre = new Timestamp(mainTime.getTime() + (long) (tempsAttente * 60 * 1000));
        }

        List<Reservation> aRetirer = new ArrayList<>();
        for (Reservation reservation : remaining) {
            Timestamp rTime = reservation.getDateArriverAsTimestamp();
            if (mainTime != null && rTime != null && finFenetre != null
                    && !rTime.before(mainTime) && !rTime.after(finFenetre)) {
                groupe.add(reservation);
                aRetirer.add(reservation);
            }
        }
        remaining.removeAll(aRetirer);

        groupe.sort((a, b) -> Integer.compare(b.getNombrePassager(), a.getNombrePassager()));
        return groupe;
    }

    private Timestamp trouverHeureArriveeMax(List<Reservation> groupe) {
        Timestamp heureArriveeMax = null;
        for (Reservation reservation : groupe) {
            Timestamp rTime = reservation.getDateArriverAsTimestamp();
            if (rTime != null && (heureArriveeMax == null || rTime.after(heureArriveeMax))) {
                heureArriveeMax = rTime;
            }
        }
        return heureArriveeMax;
    }

    private Map<Integer, Integer> initialiserPassagersRestants(List<Reservation> groupe) {
        Map<Integer, Integer> passagersRestants = new LinkedHashMap<>();
        for (Reservation reservation : groupe) {
            passagersRestants.put(reservation.getId(), reservation.getNombrePassager());
        }
        return passagersRestants;
    }

    private Reservation trouverReservationCible(List<Reservation> groupe, Map<Integer, Integer> passagersRestants) {
        for (Reservation reservation : groupe) {
            Integer restants = passagersRestants.get(reservation.getId());
            if (restants != null && restants > 0) {
                return reservation;
            }
        }
        return null;
    }

    private int assignerReservationCible(AssignationVoiture assignation, Reservation cible,
            Map<Integer, Integer> passagersRestants, int passagersCible, int capaciteRestante,
            boolean cibleFullFitPossible, Voiture voiture) {
        int aAssignerCible = cibleFullFitPossible ? passagersCible : Math.min(passagersCible, capaciteRestante);
        if (aAssignerCible <= 0) {
            return capaciteRestante;
        }

        assignation.addReservationPartielle(cible, aAssignerCible);
        passagersRestants.put(cible.getId(), passagersCible - aAssignerCible);

        int nouvelleCapacite = capaciteRestante - aAssignerCible;
        if (aAssignerCible < passagersCible) {
            System.out.printf("[Assignation partielle] Client %d: %d/%d pass -> Voiture %s (reste %d places)%n",
                    cible.getIdClient(), aAssignerCible, passagersCible, voiture.getMatricule(), nouvelleCapacite);
        } else {
            System.out.printf("[Assignation] Client %d: %d pass -> Voiture %s (reste %d places)%n",
                    cible.getIdClient(), aAssignerCible, voiture.getMatricule(), nouvelleCapacite);
        }

        return nouvelleCapacite;
    }

    private int remplirVoitureAvecAutresReservations(AssignationVoiture assignation, List<Reservation> groupe,
            Map<Integer, Integer> passagersRestants, Reservation cible, int capaciteRestante,
            Timestamp heureArriveeMax, Voiture voitureCourante) {
        if (capaciteRestante <= 0) {
            return capaciteRestante;
        }

        List<Integer> reservationsIgnoreesPourCetteVoiture = new ArrayList<>();
        while (capaciteRestante > 0) {
            Reservation meilleureReservation = trouverMeilleureReservationPourCapacite(groupe, passagersRestants,
                    cible, reservationsIgnoreesPourCetteVoiture, capaciteRestante);
            if (meilleureReservation == null) {
                break;
            }

            int restantsMeilleur = passagersRestants.get(meilleureReservation.getId());
            Voiture fullFitForR = trouverMeilleureVoitureDisponible(restantsMeilleur, heureArriveeMax, voitureCourante);
            int aAssigner = (fullFitForR != null)
                    ? (restantsMeilleur <= capaciteRestante ? restantsMeilleur : 0)
                    : Math.min(restantsMeilleur, capaciteRestante);

            if (aAssigner <= 0) {
                reservationsIgnoreesPourCetteVoiture.add(meilleureReservation.getId());
                continue;
            }

            assignation.addReservationPartielle(meilleureReservation, aAssigner);
            passagersRestants.put(meilleureReservation.getId(), restantsMeilleur - aAssigner);
            capaciteRestante -= aAssigner;

            if (aAssigner < restantsMeilleur) {
                System.out.printf("[Assignation partielle] Client %d: %d/%d pass -> Voiture %s (reste %d places)%n",
                        meilleureReservation.getIdClient(), aAssigner, restantsMeilleur, voitureCourante.getMatricule(),
                        capaciteRestante);
            } else {
                System.out.printf("[Assignation] Client %d: %d pass -> Voiture %s (reste %d places)%n",
                        meilleureReservation.getIdClient(), aAssigner, voitureCourante.getMatricule(), capaciteRestante);
            }
        }

        return capaciteRestante;
    }

    private Reservation trouverMeilleureReservationPourCapacite(List<Reservation> groupe,
            Map<Integer, Integer> passagersRestants, Reservation cible, List<Integer> reservationsIgnoreesPourCetteVoiture,
            int capaciteRestante) {
        Reservation meilleureReservation = null;
        int restantsMeilleur = 0;
        int meilleurEcart = Integer.MAX_VALUE;

        for (Reservation reservation : groupe) {
            if (reservation.getId() == cible.getId()) {
                continue;
            }
            if (reservationsIgnoreesPourCetteVoiture.contains(reservation.getId())) {
                continue;
            }

            Integer restants = passagersRestants.get(reservation.getId());
            if (restants == null || restants <= 0) {
                continue;
            }

            int ecart = Math.abs(restants - capaciteRestante);
            if (ecart < meilleurEcart
                    || (ecart == meilleurEcart && restants < restantsMeilleur)
                    || (ecart == meilleurEcart && restants == restantsMeilleur
                            && (meilleureReservation == null || reservation.getId() < meilleureReservation.getId()))) {
                meilleurEcart = ecart;
                meilleureReservation = reservation;
                restantsMeilleur = restants;
            }
        }

        return meilleureReservation;
    }

    private void marquerPassagersNonAssignes(List<AssignationVoiture> assignations, List<Reservation> groupe,
            Map<Integer, Integer> passagersRestants) {
        System.out.printf("[Non assigné] Plus de voitures disponibles, %d passagers restants%n",
                getTotalPassagersRestants(passagersRestants));

        for (Reservation reservation : groupe) {
            int restants = passagersRestants.get(reservation.getId());
            if (restants > 0) {
                AssignationVoiture assignation = new AssignationVoiture();
                assignation.addReservationPartielle(reservation, restants);
                assignation.setReservation(reservation);
                assignations.add(assignation);
                System.out.printf("[Non assigné] Client %d: %d passagers non assignés%n",
                        reservation.getIdClient(), restants);
                passagersRestants.put(reservation.getId(), 0);
            }
        }
    }

    private Timestamp calculerHeureDepart(Timestamp heureArriveeMax, Voiture voiture) {
        Timestamp heureDepart = heureArriveeMax;
        if (voiture != null && voiture.getHeureRetourAeroport() != null) {
            if (heureDepart == null || voiture.getHeureRetourAeroport().after(heureDepart)) {
                heureDepart = voiture.getHeureRetourAeroport();
            }
        }
        return heureDepart;
    }

    private void finaliserAssignation(AssignationVoiture assignation, Voiture voiture, Reservation cible,
            Timestamp heureDepart, Lieu aeroportGlobal, List<Distance> allDistances, double vitesse) {
        Reservation reservationDepart = buildReservationForDepart(cible, heureDepart);
        assignation.setReservation(reservationDepart);

        Lieu aeroportLocal = (assignation.getReservation() != null
                && assignation.getReservation().getLieuAtterissage() != null)
                        ? assignation.getReservation().getLieuAtterissage()
                        : aeroportGlobal;
        computeItineraire(assignation, aeroportLocal, allDistances, vitesse);

        if (assignation.getHeureRetourAeroport() != null && heureDepart != null) {
            try {
                String heureRetourStr = heureDepart.toString().substring(0, 11)
                        + assignation.getHeureRetourAeroport() + ":00";
                Timestamp heureRetour = Timestamp.valueOf(heureRetourStr);
                voiture.setHeureRetourAeroport(heureRetour);
                System.out.printf("[Trajet] Voiture %s - Départ: %s - Retour prévu: %s%n",
                        voiture.getMatricule(), heureDepart.toString().substring(11, 16),
                        assignation.getHeureRetourAeroport());
            } catch (Exception e) {
                System.out.println("Erreur calcul heure retour: " + e.getMessage());
            }
        }
    }

    /**
     * Vérifie s'il reste des passagers à assigner
     */
    private boolean hasPassagersRestants(Map<Integer, Integer> passagersRestants) {
        for (Integer passagers : passagersRestants.values()) {
            if (passagers > 0) return true;
        }
        return false;
    }

    /**
     * Retourne le total des passagers restants
     */
    private int getTotalPassagersRestants(Map<Integer, Integer> passagersRestants) {
        int total = 0;
        for (Integer passagers : passagersRestants.values()) {
            total += passagers;
        }
        return total;
    }

    /**
     * Trouve la meilleure voiture disponible à une heure donnée selon les règles:
     * 1. Capacité suffisante
     * 2. Disponible à l'heure demandée (heureRetour <= heureDepart)
     * 3. Priorité: moins de trajets > moins d'écart de places > diesel > random
     * @param excludeVoiture Voiture à exclure (par exemple la voiture courante en cours de remplissage)
     */
    private Voiture trouverMeilleureVoitureDisponible(int nombrePassagers, Timestamp heureDepart, Voiture excludeVoiture) {
        List<Voiture> candidates = new ArrayList<>();

        for (Voiture v : voituresDisponibles) {
            if (excludeVoiture != null && v.getId() == excludeVoiture.getId()) {
                continue;
            }
            if (v.getNombrePlaces() >= nombrePassagers && v.estDisponibleA(heureDepart)) {
                candidates.add(v);
            }
        }

        if (candidates.isEmpty()) {
            return null;
        }

        int minTrajets = Integer.MAX_VALUE;
        for (Voiture voiture : candidates) {
            minTrajets = Math.min(minTrajets, voiture.getNombreTrajets());
        }

        List<Voiture> meilleuresVoitures = new ArrayList<>();
        for (Voiture voiture : candidates) {
            if (voiture.getNombreTrajets() == minTrajets) {
                meilleuresVoitures.add(voiture);
            }
        }

        int minEcart = Integer.MAX_VALUE;
        for (Voiture voiture : meilleuresVoitures) {
            minEcart = Math.min(minEcart, voiture.getNombrePlaces() - nombrePassagers);
        }

        List<Voiture> meilleuresSelonEcart = new ArrayList<>();
        for (Voiture voiture : meilleuresVoitures) {
            if (voiture.getNombrePlaces() - nombrePassagers == minEcart) {
                meilleuresSelonEcart.add(voiture);
            }
        }

        boolean dieselDisponible = false;
        for (Voiture voiture : meilleuresSelonEcart) {
            if ("D".equals(voiture.getTypeCarburant())) {
                dieselDisponible = true;
                break;
            }
        }

        List<Voiture> finales = new ArrayList<>();
        if (dieselDisponible) {
            for (Voiture voiture : meilleuresSelonEcart) {
                if ("D".equals(voiture.getTypeCarburant())) {
                    finales.add(voiture);
                }
            }
        } else {
            finales.addAll(meilleuresSelonEcart);
        }

        if (finales.isEmpty()) {
            return null;
        }

        return finales.get(ThreadLocalRandom.current().nextInt(finales.size()));
    }

    /**
     * Trouve la prochaine voiture qui sera disponible (celle avec l'heure de retour la plus proche)
     */
    private Voiture trouverProchaineVoitureDisponible(int nombrePassagers) {
        Voiture prochaine = null;
        Timestamp heureRetourMin = null;

        for (Voiture v : voituresDisponibles) {
            if (v.getNombrePlaces() >= nombrePassagers && v.getHeureRetourAeroport() != null) {
                if (heureRetourMin == null || v.getHeureRetourAeroport().before(heureRetourMin)) {
                    heureRetourMin = v.getHeureRetourAeroport();
                    prochaine = v;
                }
            }
        }

        return prochaine;
    }

    /**
     * Crée une copie légère de réservation pour porter l'heure de départ calculée
     * sans modifier l'heure d'arrivée originale utilisée dans l'affichage.
     */
    private Reservation buildReservationForDepart(Reservation source, Timestamp heureDepart) {
        if (source == null) {
            return null;
        }

        Reservation copy = new Reservation(
            source.getId(),
            source.getIdClient(),
            source.getDateArriverAsTimestamp(),
            source.getNombrePassager(),
            source.getLieu(),
            source.getLieuAtterissage()
        );

        if (heureDepart != null) {
            copy.setDateArriver(heureDepart.toString());
        }

        return copy;
    }
}
