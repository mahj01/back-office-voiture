package org.itu.util;

import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

import org.itu.entity.AssignationVoiture;
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
     * Assigne les voitures aux réservations pour une date donnée
     */
    public List<AssignationVoiture> assignerVoitures(Date date) {
        List<AssignationVoiture> assignations = new ArrayList<>();
        
        // Récupérer toutes les voitures disponibles
        voituresDisponibles = getAllVoitures();
        
        // Récupérer les réservations du jour
        List<Reservation> reservations = getReservationsByDate(date);
        
        // Pour chaque réservation, trouver la meilleure voiture
        for (Reservation reservation : reservations) {
            Voiture voitureAssignee = trouverMeilleureVoiture(reservation.getNombrePassager());
            
            AssignationVoiture assignation = new AssignationVoiture(reservation, voitureAssignee);
            assignations.add(assignation);
            
            // Retirer la voiture de la liste des disponibles
            if (voitureAssignee != null) {
                voituresDisponibles.removeIf(v -> v.getId() == voitureAssignee.getId());
            }
        }
        
        return assignations;
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
