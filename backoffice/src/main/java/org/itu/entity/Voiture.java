package org.itu.entity;

import java.math.BigDecimal;

import org.itu.util.DB;

public class Voiture {
    private int id;
    private String matricule;
    private String marque;
    private String modele;
    private int nombrePlaces;
    private String typeCarburant;
    private BigDecimal vitesseMoyenne;
    private BigDecimal tempAttente;
    private java.sql.Timestamp departHeureDisponibilite;

    // Champs runtime pour le suivi des trajets (non persistés en BDD)
    private int nombreTrajets = 0;
    private java.sql.Timestamp heureRetourAeroport = null; // null = disponible dès 00:00

    private DB db;

    public Voiture() {
    }
    public void connectDB(DB db) {
        this.db = db;
    }
    public int getId() {
        return id;
    }
    public void setId(int id) {
        this.id = id;
    }
    public String getMatricule() {
        return matricule;
    }
    public void setMatricule(String matricule) {
        this.matricule = matricule;
    }
    public String getMarque() {
        return marque;
    }
    public void setMarque(String marque) {
        this.marque = marque;
    }
    public String getModele() {
        return modele;
    }
    public void setModele(String modele) {
        this.modele = modele;
    }
    public int getNombrePlaces() {
        return nombrePlaces;
    }
    public void setNombrePlaces(int nombrePlaces) {
        this.nombrePlaces = nombrePlaces;
    }
    public String getTypeCarburant() {
        return typeCarburant;
    }
    public void setTypeCarburant(String typeCarburant) {
        this.typeCarburant = typeCarburant;
    }
    public BigDecimal getVitesseMoyenne() {
        return vitesseMoyenne;
    }
    public void setVitesseMoyenne(BigDecimal vitesseMoyenne) {
        this.vitesseMoyenne = vitesseMoyenne;
    }
    public BigDecimal getTempAttente() {
        return tempAttente;
    }
    public void setTempAttente(BigDecimal tempAttente) {
        this.tempAttente = tempAttente;
    }
    public java.sql.Timestamp getDepartHeureDisponibilite() {
        return departHeureDisponibilite;
    }
    public void setDepartHeureDisponibilite(java.sql.Timestamp departHeureDisponibilite) {
        this.departHeureDisponibilite = departHeureDisponibilite;
    }
    public Voiture(int id, String matricule, String marque, String modele, int nombrePlaces, String typeCarburant) {
        this.id = id;
        this.matricule = matricule;
        this.marque = marque;
        this.modele = modele;
        this.nombrePlaces = nombrePlaces;
        this.typeCarburant = typeCarburant;
    }
    public Voiture(int id, String matricule, String marque, String modele, int nombrePlaces, String typeCarburant, BigDecimal vitesseMoyenne, BigDecimal tempAttente) {
        this.id = id;
        this.matricule = matricule;
        this.marque = marque;
        this.modele = modele;
        this.nombrePlaces = nombrePlaces;
        this.typeCarburant = typeCarburant;
        this.vitesseMoyenne = vitesseMoyenne;
        this.tempAttente = tempAttente;
    }

    public Voiture(int id, String matricule, String marque, String modele, int nombrePlaces, String typeCarburant,
            BigDecimal vitesseMoyenne, BigDecimal tempAttente, java.sql.Timestamp departHeureDisponibilite) {
        this(id, matricule, marque, modele, nombrePlaces, typeCarburant, vitesseMoyenne, tempAttente);
        this.departHeureDisponibilite = departHeureDisponibilite;
    }

    public void delete() {
        String sql = "DELETE FROM voiture WHERE id = ?";
        try (java.sql.PreparedStatement stmt = db.getConnection().prepareStatement(sql)) {
            stmt.setInt(1, this.id);
            stmt.executeUpdate();
            System.out.println("Voiture supprimée avec succès.");
        } catch (java.sql.SQLException e) {
            System.out.println("Erreur lors de la suppression de la voiture : " + e.getMessage());
        }
    }

    public void createVoiture() {
        String sql = "INSERT INTO voiture (matricule, marque, model, nombre_place, type_carburant, vitesse_moyenne, temp_attente, depart_heure_disponibilite) VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
        try (java.sql.PreparedStatement stmt = db.getConnection().prepareStatement(sql)) {
            stmt.setString(1, this.matricule);
            stmt.setString(2, this.marque);
            stmt.setString(3, this.modele);
            stmt.setInt(4, this.nombrePlaces);
            stmt.setString(5, this.typeCarburant);
            stmt.setBigDecimal(6, this.vitesseMoyenne);
            stmt.setBigDecimal(7, this.tempAttente);
            stmt.setTimestamp(8, this.departHeureDisponibilite);
            stmt.executeUpdate();
            System.out.println("Voiture créée avec succès.");
        } catch (java.sql.SQLException e) {
            System.out.println("Erreur lors de la création de la voiture : " + e.getMessage());
        }   
    }

    public void updateVoiture() {
        String sql = "UPDATE voiture SET matricule = ?, marque = ?, model = ?, nombre_place = ?, type_carburant = ?, vitesse_moyenne = ?, temp_attente = ?, depart_heure_disponibilite = ? WHERE id = ?";
        try (java.sql.PreparedStatement stmt = db.getConnection().prepareStatement(sql)) {
            stmt.setString(1, this.matricule);
            stmt.setString(2, this.marque);
            stmt.setString(3, this.modele);
            stmt.setInt(4, this.nombrePlaces);
            stmt.setString(5, this.typeCarburant);
            stmt.setBigDecimal(6, this.vitesseMoyenne);
            stmt.setBigDecimal(7, this.tempAttente);
            stmt.setTimestamp(8, this.departHeureDisponibilite);
            stmt.setInt(9, this.id);
            stmt.executeUpdate();
            System.out.println("Voiture mise à jour avec succès.");
        } catch (java.sql.SQLException e) {
            System.out.println("Erreur lors de la mise à jour de la voiture : " + e.getMessage());
        }
    }

    // --- Méthodes pour le suivi des trajets (runtime) ---

    public int getNombreTrajets() {
        return nombreTrajets;
    }

    public void setNombreTrajets(int nombreTrajets) {
        this.nombreTrajets = nombreTrajets;
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
     * Une voiture est disponible si:
     * - Elle n'a pas encore fait de trajet (heureRetourAeroport == null)
     * - Ou si l'heure donnée est >= heureRetourAeroport
     */
    public boolean estDisponibleA(java.sql.Timestamp heure) {
        if (heure == null) {
            return departHeureDisponibilite == null && heureRetourAeroport == null;
        }

        // Seuil effectif = max(depart_heure_disponibilite, heure_retour_runtime)
        java.sql.Timestamp seuilDisponibilite = departHeureDisponibilite;
        if (heureRetourAeroport != null
                && (seuilDisponibilite == null || heureRetourAeroport.after(seuilDisponibilite))) {
            seuilDisponibilite = heureRetourAeroport;
        }

        return seuilDisponibilite == null || !heure.before(seuilDisponibilite);
    }
}
