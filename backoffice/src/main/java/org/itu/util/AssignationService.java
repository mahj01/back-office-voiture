package org.itu.util;

import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.itu.entity.AssignationVoiture;
import org.itu.entity.Distance;
import org.itu.entity.Lieu;
import org.itu.entity.Reservation;
import org.itu.entity.Voiture;

/**
 * Service pour assigner les voitures aux réservations selon les règles:
 * 1. nombrePlaces >= nombrePassagers
 * 2. Prioriser la voiture avec le moins de trajets effectués
 * 3. Prendre la voiture avec le moins d'écart de places
 * 4. Si égalité, prendre diesel (type_carburant = 'D')
 * 5. Si encore égalité, prendre au hasard
 * 6. Une voiture est disponible à partir de son heure de retour à l'aéroport
 * 7. L'heure de départ = max(heure arrivée dernier passager, heure retour voiture)
 */
public class AssignationService {
    private DB db;
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
        String sql = "SELECT id, matricule, marque, model, nombre_place, type_carburant, vitesse_moyenne, temp_attente FROM voiture ORDER BY nombre_place, type_carburant";
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
                    rs.getBigDecimal("temp_attente")
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
            e.printStackTrace();
        }
        return reservations;
    }

    /**
     * Assigne les voitures aux réservations pour une date donnée.
     * Nouvelles règles Sprint 6:
     * 1. Sous-grouper par aéroport (lieu d'atterrissage)
     * 2. Trier par heure d'arrivée chronologique
     * 3. Pour chaque groupe, trouver la meilleure voiture DISPONIBLE selon:
     *    - Priorité 1: Nombre de trajets le plus bas
     *    - Priorité 2: Meilleur fit (moins d'écart de places)
     *    - Priorité 3: Diesel préféré
     *    - Priorité 4: Random si égalité
     * 4. Une voiture est disponible si son heure de retour <= heure de départ souhaitée
     * 5. Si aucune voiture disponible immédiatement, attendre la prochaine disponible
     * 6. Heure de départ = max(heure arrivée dernier passager, heure retour voiture)
     * 7. Après chaque assignation, recalculer les réservations non assignées
     */
    public List<AssignationVoiture> assignerVoitures(Date date) {
        List<AssignationVoiture> assignations = new ArrayList<>();

        // Récupérer toutes les voitures disponibles et réinitialiser les trajets
        voituresDisponibles = getAllVoitures();
        for (Voiture v : voituresDisponibles) {
            v.setNombreTrajets(0);
            v.setHeureRetourAeroport(null); // Toutes disponibles à 00:00
        }

        // Récupérer les réservations du jour
        List<Reservation> reservations = getReservationsByDate(date);

        // Récupérer le temps d'attente global (TA) en minutes
        double tempsAttente = getTempsAttenteMinutes();

        // Récupérer les données pour le calcul d'itinéraire
        Lieu aeroportGlobal = getAeroport();
        List<Distance> allDistances = getAllDistances();
        double vitesse = getVitesseKmH();

        // Sous-grouper par aéroport (lieu d'atterrissage)
        Map<Integer, List<Reservation>> airportGroups = new LinkedHashMap<>();
        for (Reservation r : reservations) {
            int aeroId = (r.getLieuAtterissage() != null && r.getLieuAtterissage().getId() != null)
                         ? r.getLieuAtterissage().getId() : 0;
            airportGroups.computeIfAbsent(aeroId, k -> new ArrayList<>()).add(r);
        }

        // Traiter chaque sous-groupe aéroport
        for (List<Reservation> airportReservations : airportGroups.values()) {
            // Trier par heure d'arrivée chronologique (plus tôt en premier)
            airportReservations.sort((a, b) -> {
                String da = a.getDateArriver() != null ? a.getDateArriver() : "";
                String db2 = b.getDateArriver() != null ? b.getDateArriver() : "";
                return da.compareTo(db2);
            });

            List<Reservation> remaining = new ArrayList<>(airportReservations);
            List<Reservation> nonAssignees = new ArrayList<>();

            while (!remaining.isEmpty()) {
                // Prendre la première réservation (la plus tôt)
                Reservation mainReservation = remaining.remove(0);
                Timestamp mainTime = mainReservation.getDateArriverAsTimestamp();

                // Calculer la fenêtre de temps [mainTime, mainTime + TA]
                Timestamp finFenetre = null;
                if (mainTime != null) {
                    finFenetre = new Timestamp(mainTime.getTime() + (long)(tempsAttente * 60 * 1000));
                }

                // Regrouper les réservations dans la fenêtre de temps
                List<Reservation> groupe = new ArrayList<>();
                groupe.add(mainReservation);
                int totalPassagers = mainReservation.getNombrePassager();

                List<Reservation> aRetirer = new ArrayList<>();
                for (Reservation r : remaining) {
                    Timestamp rTime = r.getDateArriverAsTimestamp();
                    if (mainTime != null && rTime != null && finFenetre != null) {
                        if (!rTime.before(mainTime) && !rTime.after(finFenetre)) {
                            // Dans la fenêtre, on l'ajoute au groupe potentiel
                            groupe.add(r);
                            aRetirer.add(r);
                        }
                    }
                }
                remaining.removeAll(aRetirer);

                // Trier le groupe par nombre de passagers décroissant
                groupe.sort((a, b) -> b.getNombrePassager() - a.getNombrePassager());

                // Calculer le nombre total de passagers pour trouver une voiture
                totalPassagers = 0;
                for (Reservation r : groupe) {
                    totalPassagers += r.getNombrePassager();
                }

                // Trouver l'heure d'arrivée la plus tardive dans le groupe
                Timestamp heureArriveeMax = mainTime;
                for (Reservation r : groupe) {
                    Timestamp rTime = r.getDateArriverAsTimestamp();
                    if (rTime != null && (heureArriveeMax == null || rTime.after(heureArriveeMax))) {
                        heureArriveeMax = rTime;
                    }
                }

                // Trouver la meilleure voiture disponible
                Voiture bestVoiture = trouverMeilleureVoitureDisponible(totalPassagers, heureArriveeMax);

                if (bestVoiture != null) {
                    // Calculer l'heure de départ = max(heureArriveeMax, heureRetourVoiture)
                    Timestamp heureDepart = heureArriveeMax;
                    if (bestVoiture.getHeureRetourAeroport() != null && heureArriveeMax != null) {
                        if (bestVoiture.getHeureRetourAeroport().after(heureArriveeMax)) {
                            heureDepart = bestVoiture.getHeureRetourAeroport();
                        }
                    } else if (bestVoiture.getHeureRetourAeroport() != null && heureArriveeMax == null) {
                        heureDepart = bestVoiture.getHeureRetourAeroport();
                    }

                    // Créer l'assignation avec les réservations qui rentrent
                    AssignationVoiture assignation = new AssignationVoiture();
                    assignation.setVoiture(bestVoiture);
                    int capaciteRestante = bestVoiture.getNombrePlaces();

                    // Ajouter les réservations qui rentrent dans la capacité
                    List<Reservation> aReporter = new ArrayList<>();
                    for (Reservation r : groupe) {
                        if (r.getNombrePassager() <= capaciteRestante) {
                            assignation.addReservation(r);
                            capaciteRestante -= r.getNombrePassager();
                        } else {
                            // Remet dans remaining pour être regroupé avec le prochain groupe
                            // (pas de groupe spécial)
                            aReporter.add(r);
                        }
                    }

                    // Reporter les réservations qui ne rentrent pas au prochain groupe
                    if (!aReporter.isEmpty()) {
                        remaining.addAll(aReporter);
                        // Retrier remaining par heure d'arrivée
                        remaining.sort((a1, b1) -> {
                            String da1 = a1.getDateArriver() != null ? a1.getDateArriver() : "";
                            String db1 = b1.getDateArriver() != null ? b1.getDateArriver() : "";
                            return da1.compareTo(db1);
                        });
                        System.out.printf("[Report capacité] %d réservation(s) reportée(s) au prochain groupe%n",
                            aReporter.size());
                    }

                    // Définir la réservation principale (celle avec l'heure de départ)
                    Reservation reservationDepart = assignation.getReservations().get(0);
                    for (Reservation r : assignation.getReservations()) {
                        if (r.getDateArriverAsTimestamp() != null &&
                            r.getDateArriverAsTimestamp().equals(heureDepart)) {
                            reservationDepart = r;
                            break;
                        }
                    }
                    // Mettre à jour la date d'arrivée pour refléter l'heure de départ réelle
                    if (heureDepart != null && !heureDepart.equals(heureArriveeMax)) {
                        // Créer une copie pour ne pas modifier l'original
                        reservationDepart.setDateArriver(heureDepart.toString());
                    }
                    assignation.setReservation(reservationDepart);

                    // Calculer l'itinéraire et l'heure de retour
                    Lieu aeroportLocal = (assignation.getReservation() != null
                            && assignation.getReservation().getLieuAtterissage() != null)
                            ? assignation.getReservation().getLieuAtterissage()
                            : aeroportGlobal;
                    computeItineraire(assignation, aeroportLocal, allDistances, vitesse);

                    // Mettre à jour l'heure de retour de la voiture
                    if (assignation.getHeureRetourAeroport() != null && heureDepart != null) {
                        try {
                            String heureRetourStr = heureDepart.toString().substring(0, 11)
                                + assignation.getHeureRetourAeroport() + ":00";
                            Timestamp heureRetour = Timestamp.valueOf(heureRetourStr);
                            bestVoiture.setHeureRetourAeroport(heureRetour);
                            System.out.printf("[Trajet] Voiture %s - Départ: %s - Retour prévu: %s%n",
                                bestVoiture.getMatricule(),
                                heureDepart.toString().substring(11, 16),
                                assignation.getHeureRetourAeroport());
                        } catch (Exception e) {
                            System.out.println("Erreur calcul heure retour: " + e.getMessage());
                        }
                    }

                    // Incrémenter le compteur de trajets
                    bestVoiture.incrementerTrajets();
                    System.out.printf("[Statistiques] Voiture %s a maintenant fait %d trajet(s)%n",
                        bestVoiture.getMatricule(), bestVoiture.getNombreTrajets());

                    assignations.add(assignation);
                } else {
                    // Aucune voiture disponible maintenant
                    // RÈGLE: Si il y a d'autres réservations après, remettre ce groupe
                    // dans remaining pour qu'il soit regroupé avec le prochain groupe
                    // (pas de groupe spécial à l'heure de retour de la voiture)

                    if (!remaining.isEmpty()) {
                        // Il y a d'autres réservations après -> reporter au prochain groupe
                        System.out.printf("[Report] Groupe de %d réservation(s) reporté au prochain groupe%n",
                            groupe.size());

                        // Remettre les réservations du groupe au début de remaining
                        // pour qu'elles soient regroupées avec le prochain groupe
                        remaining.addAll(0, groupe);

                        // Retrier remaining par heure (la prochaine réservation originale devient la principale)
                        remaining.sort((a, b) -> {
                            String da = a.getDateArriver() != null ? a.getDateArriver() : "";
                            String db2 = b.getDateArriver() != null ? b.getDateArriver() : "";
                            return da.compareTo(db2);
                        });

                        // Retirer les réservations du groupe actuel (elles seront regroupées avec le prochain)
                        // En fait, on les garde mais la prochaine itération va former un nouveau groupe
                        // incluant la prochaine réservation (qui est hors fenêtre du groupe actuel)

                        // Trouver la prochaine réservation hors de la fenêtre actuelle
                        Reservation prochaineHorsFenetre = null;
                        for (Reservation r : remaining) {
                            Timestamp rTime = r.getDateArriverAsTimestamp();
                            if (rTime != null && finFenetre != null && rTime.after(finFenetre)) {
                                prochaineHorsFenetre = r;
                                break;
                            }
                        }

                        if (prochaineHorsFenetre != null) {
                            // Réorganiser remaining pour que la prochaine réservation hors fenêtre soit en tête
                            remaining.remove(prochaineHorsFenetre);
                            remaining.add(0, prochaineHorsFenetre);
                        }

                        // Continuer avec le prochain groupe
                        continue;
                    }

                    // Plus de réservations après -> chercher la prochaine voiture disponible
                    Voiture prochaineVoiture = trouverProchaineVoitureDisponible(totalPassagers);

                    if (prochaineVoiture != null && prochaineVoiture.getHeureRetourAeroport() != null) {
                        // Attendre que la voiture revienne
                        Timestamp heureDepart = prochaineVoiture.getHeureRetourAeroport();

                        AssignationVoiture assignation = new AssignationVoiture();
                        assignation.setVoiture(prochaineVoiture);
                        int capaciteRestante = prochaineVoiture.getNombrePlaces();

                        for (Reservation r : groupe) {
                            if (r.getNombrePassager() <= capaciteRestante) {
                                assignation.addReservation(r);
                                capaciteRestante -= r.getNombrePassager();
                            } else {
                                nonAssignees.add(r);
                            }
                        }

                        // Mettre à jour l'heure de départ
                        Reservation reservationDepart = assignation.getReservations().get(0);
                        reservationDepart.setDateArriver(heureDepart.toString());
                        assignation.setReservation(reservationDepart);

                        Lieu aeroportLocal = (assignation.getReservation() != null
                                && assignation.getReservation().getLieuAtterissage() != null)
                                ? assignation.getReservation().getLieuAtterissage()
                                : aeroportGlobal;
                        computeItineraire(assignation, aeroportLocal, allDistances, vitesse);

                        // Mettre à jour l'heure de retour
                        if (assignation.getHeureRetourAeroport() != null) {
                            try {
                                String heureRetourStr = heureDepart.toString().substring(0, 11)
                                    + assignation.getHeureRetourAeroport() + ":00";
                                Timestamp heureRetour = Timestamp.valueOf(heureRetourStr);
                                prochaineVoiture.setHeureRetourAeroport(heureRetour);
                            } catch (Exception e) {
                                System.out.println("Erreur calcul heure retour: " + e.getMessage());
                            }
                        }

                        prochaineVoiture.incrementerTrajets();
                        assignations.add(assignation);
                    } else {
                        // Aucune voiture ne peut prendre ce groupe
                        for (Reservation r : groupe) {
                            AssignationVoiture assignation = new AssignationVoiture(r, null);
                            assignations.add(assignation);
                        }
                    }
                }
            }

            // Réassigner les réservations non assignées avec les voitures revenues
            if (!nonAssignees.isEmpty()) {
                System.out.printf("[Réassignation] %d réservation(s) non assignée(s), tentative de réassignation...%n",
                    nonAssignees.size());

                for (Reservation r : nonAssignees) {
                    Timestamp rTime = r.getDateArriverAsTimestamp();
                    Voiture voiture = trouverMeilleureVoitureDisponible(r.getNombrePassager(), rTime);

                    if (voiture == null) {
                        voiture = trouverProchaineVoitureDisponible(r.getNombrePassager());
                    }

                    AssignationVoiture assignation = new AssignationVoiture(r, voiture);

                    if (voiture != null) {
                        Timestamp heureDepart = rTime;
                        if (voiture.getHeureRetourAeroport() != null && rTime != null) {
                            if (voiture.getHeureRetourAeroport().after(rTime)) {
                                heureDepart = voiture.getHeureRetourAeroport();
                                r.setDateArriver(heureDepart.toString());
                            }
                        }

                        Lieu aeroportLocal = (r.getLieuAtterissage() != null)
                                ? r.getLieuAtterissage()
                                : aeroportGlobal;
                        computeItineraire(assignation, aeroportLocal, allDistances, vitesse);

                        if (assignation.getHeureRetourAeroport() != null && heureDepart != null) {
                            try {
                                String heureRetourStr = heureDepart.toString().substring(0, 11)
                                    + assignation.getHeureRetourAeroport() + ":00";
                                Timestamp heureRetour = Timestamp.valueOf(heureRetourStr);
                                voiture.setHeureRetourAeroport(heureRetour);
                            } catch (Exception e) {
                                System.out.println("Erreur calcul heure retour: " + e.getMessage());
                            }
                        }
                        voiture.incrementerTrajets();
                    }

                    assignations.add(assignation);
                }
            }
        }

        return assignations;
    }

    /**
     * Trouve la meilleure voiture disponible à une heure donnée selon les règles:
     * 1. Capacité suffisante
     * 2. Disponible à l'heure demandée (heureRetour <= heureDepart)
     * 3. Priorité: moins de trajets > moins d'écart de places > diesel > random
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

                // 2. Écart de places (moins = mieux, mais la voiture doit suffire)
                int ecartA = a.getNombrePlaces() - nombrePassagers;
                int ecartB = b.getNombrePlaces() - nombrePassagers;
                int cmpEcart = Integer.compare(ecartA, ecartB);
                if (cmpEcart != 0) return cmpEcart;

                // 3. Diesel préféré
                boolean aDiesel = "D".equals(a.getTypeCarburant());
                boolean bDiesel = "D".equals(b.getTypeCarburant());
                if (aDiesel && !bDiesel) return -1;
                if (!aDiesel && bDiesel) return 1;

                // 4. Random (utiliser l'ID comme tie-breaker déterministe)
                return Integer.compare(a.getId(), b.getId());
            }
        });

        return candidates.get(0);
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
}
