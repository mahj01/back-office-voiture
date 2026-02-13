package org.itu.entity;

import org.itu.util.DB;

public class Voiture {
    private int id;
    private String matricule;
    private String marque;
    private String modele;
    private int nombrePlaces;
    private String typeCarburant;

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
    public Voiture(int id, String matricule, String marque, String modele, int nombrePlaces, String typeCarburant) {
        this.id = id;
        this.matricule = matricule;
        this.marque = marque;
        this.modele = modele;
        this.nombrePlaces = nombrePlaces;
        this.typeCarburant = typeCarburant;
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
        String sql = "INSERT INTO voiture (matricule, marque, model, nombre_place, type_carburant) VALUES (?, ?, ?, ?, ?)";
        try (java.sql.PreparedStatement stmt = db.getConnection().prepareStatement(sql)) {
            stmt.setString(1, this.matricule);
            stmt.setString(2, this.marque);
            stmt.setString(3, this.modele);
            stmt.setInt(4, this.nombrePlaces);
            stmt.setString(5, this.typeCarburant);
            stmt.executeUpdate();
            System.out.println("Voiture créée avec succès.");
        } catch (java.sql.SQLException e) {
            System.out.println("Erreur lors de la création de la voiture : " + e.getMessage());
        }   
    }

    public void updateVoiture() {
        String sql = "UPDATE voiture SET matricule = ?, marque = ?, model = ?, nombre_place = ?, type_carburant = ? WHERE id = ?";
        try (java.sql.PreparedStatement stmt = db.getConnection().prepareStatement(sql)) {
            stmt.setString(1, this.matricule);
            stmt.setString(2, this.marque);
            stmt.setString(3, this.modele);
            stmt.setInt(4, this.nombrePlaces);
            stmt.setString(5, this.typeCarburant);
            stmt.setInt(6, this.id);
            stmt.executeUpdate();
            System.out.println("Voiture mise à jour avec succès.");
        } catch (java.sql.SQLException e) {
            System.out.println("Erreur lors de la mise à jour de la voiture : " + e.getMessage());
        }
    }
}
