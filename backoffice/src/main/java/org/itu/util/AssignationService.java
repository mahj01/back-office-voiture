package org.itu.util;

import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;

import org.itu.entity.AssignationVoiture;
import org.itu.entity.Distance;
import org.itu.entity.Lieu;
import org.itu.entity.Reservation;
import org.itu.entity.Voiture;

/**
 * Service pour assigner les voitures aux réservations selon les règles:
 * 1. nombrePlaces >= nombrePassagers
 * 2. Prendre la voiture avec le moins d'écart de places
 * 3. Si égalité, prendre diesel (type_carburant = 'D')
 * 4. Si encore égalité, prendre au hasard
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

        // --- Heure de retour = heure de départ + temps de conduite ---
        if (vitesseKmH > 0 && assignation.getReservation() != null) {
            String dateStr = assignation.getReservation().getDateArriver();
            if (dateStr != null) {
                try {
                    java.sql.Timestamp depart = java.sql.Timestamp.valueOf(dateStr);
                    long millis = (long) (tempsConduiteMin * 60 * 1000);
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
     * Les réservations avec la même heure et minute sont regroupées dans la même voiture.
     * Algorithme:
     * 1. Regrouper les réservations par heure:minute
     * 2. Trier les réservations par nombre décroissant de passagers
     * 3. Trier les voitures par nombre décroissant de places
     * 4. Prendre la réservation avec le max de passagers → voiture avec max de places
     * 5. Remplir la voiture avec d'autres réservations du même créneau si possible
     * 6. Si la voiture est pleine, répéter avec les réservations restantes
     */
    public List<AssignationVoiture> assignerVoitures(Date date) {
        List<AssignationVoiture> assignations = new ArrayList<>();
        
        // Récupérer toutes les voitures disponibles
        voituresDisponibles = getAllVoitures();
        
        // Récupérer les réservations du jour
        List<Reservation> reservations = getReservationsByDate(date);
        
        // Regrouper les réservations par date, heure et minute exacte
        Map<String, List<Reservation>> groups = new LinkedHashMap<>();
        for (Reservation r : reservations) {
            String key = getDateHourMinuteKey(r);
            groups.computeIfAbsent(key, k -> new ArrayList<>()).add(r);
        }
        
        // Traiter chaque groupe
        for (List<Reservation> group : groups.values()) {
            if (group.size() == 1) {
                // Réservation unique - logique existante (min écart, diesel, random)
                Reservation reservation = group.get(0);
                Voiture voitureAssignee = trouverMeilleureVoiture(reservation.getNombrePassager());
                
                AssignationVoiture assignation = new AssignationVoiture(reservation, voitureAssignee);
                assignations.add(assignation);
                
                if (voitureAssignee != null) {
                    voituresDisponibles.removeIf(v -> v.getId() == voitureAssignee.getId());
                }
            } else {
                // Groupe de réservations à la même heure et minute
                // Trier les réservations par nombre décroissant de passagers
                group.sort((a, b) -> b.getNombrePassager() - a.getNombrePassager());
                
                // Trier les voitures disponibles par nombre décroissant de places
                List<Voiture> voituresTriees = new ArrayList<>(voituresDisponibles);
                voituresTriees.sort((a, b) -> b.getNombrePlaces() - a.getNombrePlaces());
                
                List<Reservation> remaining = new ArrayList<>(group);
                
                while (!remaining.isEmpty()) {
                    // Prendre la première réservation (max passagers)
                    Reservation mainReservation = remaining.get(0);
                    
                    // Trouver la voiture avec le max de places qui peut contenir au moins cette réservation
                    Voiture bestVoiture = null;
                  
                    for (Voiture v : voituresTriees) {
                        if (v.getNombrePlaces() >= mainReservation.getNombrePassager()) {
                            bestVoiture = v;
                            break;
                        }
                    }
                    
                    
                    AssignationVoiture assignation = new AssignationVoiture(mainReservation, bestVoiture);
                    remaining.remove(0);
                    
                    if (bestVoiture != null) {
                        int capaciteRestante = bestVoiture.getNombrePlaces() - mainReservation.getNombrePassager();
                        
                        // Essayer de remplir la voiture avec d'autres réservations du groupe
                        List<Reservation> fitted = new ArrayList<>();
                        for (Reservation r : remaining) {
                            if (r.getNombrePassager() <= capaciteRestante) {
                                assignation.addReservation(r);
                                capaciteRestante -= r.getNombrePassager();
                                fitted.add(r);
                            }
                        }
                        remaining.removeAll(fitted);
                        
                        // Retirer cette voiture de la liste des disponibles
                        final int voitureId = bestVoiture.getId();
                        voituresDisponibles.removeIf(v -> v.getId() == voitureId);
                        voituresTriees.removeIf(v -> v.getId() == voitureId);
                    }
                    
                    assignations.add(assignation);
                }
            }
        }

        // Calculer l'itinéraire et l'heure de retour pour chaque assignation
        Lieu aeroportGlobal = getAeroport(); // fallback si pas de lieu_atterissage sur la réservation
        List<Distance> allDistances = getAllDistances();
        double vitesse = getVitesseKmH();

        for (AssignationVoiture assignation : assignations) {
            if (assignation.hasVoiture()) {
                // Utiliser l'aéroport spécifique de la réservation principale du groupe
                Lieu aeroportLocal = (assignation.getReservation() != null
                        && assignation.getReservation().getLieuAtterissage() != null)
                        ? assignation.getReservation().getLieuAtterissage()
                        : aeroportGlobal;
                computeItineraire(assignation, aeroportLocal, allDistances, vitesse);
            }
        }
        
        return assignations;
    }

    /**
     * Extrait la clé date+heure+minute d'une réservation (format: "YYYY-MM-DD HH:MM")
     */
    private String getDateHourMinuteKey(Reservation r) {
        String dateStr = r.getDateArriver();
        String dateKey = (dateStr != null && dateStr.length() >= 16) ? dateStr.substring(0, 16) : (dateStr != null ? dateStr : "");
        int aeroId = (r.getLieuAtterissage() != null && r.getLieuAtterissage().getId() != null)
                     ? r.getLieuAtterissage().getId() : 0;
        return dateKey + "_AERO_" + aeroId;
    }

    /**
     * Trouve la meilleure voiture pour un nombre de passagers donné
     * Règles:
     * 1. nombrePlaces >= nombrePassagers
     * 2. Moins d'écart de places possible
     * 3. Priorité diesel si égalité
     * 4. Random si encore égalité
     */
    private Voiture trouverMeilleureVoiture(int nombrePassagers) {
        // Filtrer les voitures avec assez de places
        List<Voiture> voituresCompatibles = new ArrayList<>();
        for (Voiture v : voituresDisponibles) {
            if (v.getNombrePlaces() >= nombrePassagers) {
                voituresCompatibles.add(v);
            }
        }
        
        if (voituresCompatibles.isEmpty()) {
            return null; // Aucune voiture disponible
        }
        
        // Trouver l'écart minimum
        int ecartMin = Integer.MAX_VALUE;
        for (Voiture v : voituresCompatibles) {
            int ecart = v.getNombrePlaces() - nombrePassagers;
            if (ecart < ecartMin && ecart >= 0) {
                ecartMin = ecart;
            }
        }
        
        // Garder seulement les voitures avec l'écart minimum
        final int finalEcartMin = ecartMin;
        List<Voiture> voituresEcartMin = new ArrayList<>();
        for (Voiture v : voituresCompatibles) {
            if (v.getNombrePlaces() - nombrePassagers == finalEcartMin) {
                voituresEcartMin.add(v);
            }
        }
        
        if (voituresEcartMin.size() == 1) {
            return voituresEcartMin.get(0);
        }
        
        // Si plusieurs, prendre diesel
        List<Voiture> voituresDiesel = new ArrayList<>();
        for (Voiture v : voituresEcartMin) {
            if ("D".equals(v.getTypeCarburant())) {
                voituresDiesel.add(v);
            }
        }
        
        if (!voituresDiesel.isEmpty()) {
            if (voituresDiesel.size() == 1) {
                return voituresDiesel.get(0);
            }
            // Si plusieurs diesel, prendre au hasard
            Random random = new Random();
            return voituresDiesel.get(random.nextInt(voituresDiesel.size()));
        }
        
        // Si pas de diesel, prendre au hasard parmi les autres
        Random random = new Random();
        return voituresEcartMin.get(random.nextInt(voituresEcartMin.size()));
    }
}
