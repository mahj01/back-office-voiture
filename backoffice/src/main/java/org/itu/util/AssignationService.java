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
                     "WHERE tl.libelle = 'AEROPORT' LIMIT 1";
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
     * Calcule l'itinéraire optimal (plus proche voisin) et l'heure de retour à l'aéroport
     * Trajet: Aéroport -> hotel le plus proche -> hotel le plus proche suivant -> ... -> Aéroport
     */
    private void computeItineraire(AssignationVoiture assignation, Lieu aeroport, List<Distance> distances, double vitesseKmH) {
        if (aeroport == null || assignation.getLieux() == null || assignation.getLieux().isEmpty()) {
            return;
        }

        // Collecter les hotels uniques à visiter (éviter les doublons par id)
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

        // Algorithme du plus proche voisin
        List<Lieu> itineraire = new ArrayList<>();
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
                // Pas de distance trouvée, on ajoute les restants sans distance
                for (Lieu remaining : hotelsToVisit) {
                    itineraire.add(remaining);
                }
                hotelsToVisit.clear();
                break;
            }

            itineraire.add(closest);
            totalKm += minDist;
            currentId = closest.getId();
            hotelsToVisit.remove(closestIndex);
        }

        // Retour à l'aéroport
        Double retourDist = findDistance(distances, currentId, aeroport.getId());
        if (retourDist != null) {
            totalKm += retourDist;
        }
        itineraire.add(aeroport);

        assignation.setItineraire(itineraire);
        assignation.setDistanceTotaleKm(Math.round(totalKm * 100.0) / 100.0);

        // Calculer l'heure de retour: heure départ + temps de trajet
        // temps = distance / vitesse
        if (vitesseKmH > 0 && assignation.getReservation() != null) {
            String dateStr = assignation.getReservation().getDateArriver();
            if (dateStr != null) {
                try {
                    java.sql.Timestamp depart = java.sql.Timestamp.valueOf(dateStr);
                    double heures = totalKm / vitesseKmH;
                    long millis = (long) (heures * 3600 * 1000);
                    java.sql.Timestamp retour = new java.sql.Timestamp(depart.getTime() + millis);
                    // Format HH:mm
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
        String sql = "SELECT * FROM voiture ORDER BY nombre_place, type_carburant";
        try (java.sql.Statement stmt = db.getConnection().createStatement();
                ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                Voiture v = new Voiture(
                    rs.getInt("id"),
                    rs.getString("matricule"),
                    rs.getString("marque"),
                    rs.getString("model"),
                    rs.getInt("nombre_place"),
                    rs.getString("type_carburant")
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
        String sql = "SELECT r.*, l.id as lieu_id, l.code, l.libelle, l.type_lieu " +
                     "FROM reservation r " +
                     "JOIN lieu l ON r.idlieu = l.id " +
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
                    Reservation r = new Reservation(
                        rs.getInt("id"),
                        rs.getInt("idclient"),
                        rs.getTimestamp("datearrivee"),
                        rs.getInt("nombrepassagers"),
                        lieu
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
     * Les réservations avec la même date et heure sont regroupées.
     * Pour chaque groupe, on cherche une voiture pour la réservation avec le plus de passagers,
     * puis on essaie d'y ajouter d'autres réservations du groupe si la capacité le permet.
     * Les lieux de chaque groupe dans la même voiture sont suivis.
     */
    public List<AssignationVoiture> assignerVoitures(Date date) {
        List<AssignationVoiture> assignations = new ArrayList<>();
        
        // Récupérer toutes les voitures disponibles
        voituresDisponibles = getAllVoitures();
        
        // Récupérer les réservations du jour
        List<Reservation> reservations = getReservationsByDate(date);
        
        // Regrouper les réservations par date et heure exacte
        Map<String, List<Reservation>> groups = new LinkedHashMap<>();
        for (Reservation r : reservations) {
            String key = getDateHourKey(r);
            groups.computeIfAbsent(key, k -> new ArrayList<>()).add(r);
        }
        
        // Traiter chaque groupe
        for (List<Reservation> group : groups.values()) {
            if (group.size() == 1) {
                // Réservation unique - logique existante
                Reservation reservation = group.get(0);
                Voiture voitureAssignee = trouverMeilleureVoiture(reservation.getNombrePassager());
                
                AssignationVoiture assignation = new AssignationVoiture(reservation, voitureAssignee);
                assignations.add(assignation);
                
                if (voitureAssignee != null) {
                    voituresDisponibles.removeIf(v -> v.getId() == voitureAssignee.getId());
                }
            } else {
                // Groupe de réservations à la même date et heure
                // Calculer le total de passagers du groupe
                int totalPassagers = 0;
                for (Reservation r : group) {
                    totalPassagers += r.getNombrePassager();
                }
                
                // Trouver la meilleure voiture pour le total du groupe
                Voiture voiture = trouverMeilleureVoiture(totalPassagers);
                
                // Prendre la première réservation comme réservation principale
                Reservation mainReservation = group.get(0);
                AssignationVoiture assignation = new AssignationVoiture(mainReservation, voiture);
                
                // Ajouter les autres réservations du groupe
                for (int i = 1; i < group.size(); i++) {
                    assignation.addReservation(group.get(i));
                }
                
                if (voiture != null) {
                    voituresDisponibles.removeIf(v -> v.getId() == voiture.getId());
                }
                
                assignations.add(assignation);
            }
        }

        // Calculer l'itinéraire et l'heure de retour pour chaque assignation
        Lieu aeroport = getAeroport();
        List<Distance> allDistances = getAllDistances();
        double vitesse = getVitesseKmH();

        for (AssignationVoiture assignation : assignations) {
            if (assignation.hasVoiture()) {
                computeItineraire(assignation, aeroport, allDistances, vitesse);
            }
        }
        
        return assignations;
    }

    /**
     * Extrait la clé date+heure d'une réservation (format: "YYYY-MM-DD HH")
     */
    private String getDateHourKey(Reservation r) {
        String dateStr = r.getDateArriver();
        if (dateStr != null && dateStr.length() >= 13) {
            return dateStr.substring(0, 13);
        }
        return dateStr != null ? dateStr : "";
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
            if (ecart < ecartMin) {
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
