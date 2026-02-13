package org.itu.util;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

import org.itu.entity.Voiture;

public class FonctionVoiture {
    private DB db;

    public FonctionVoiture(DB db) {
        this.db = db;
    }

    public List<Voiture> getAllVoitures() {
        List<Voiture> voitures = new ArrayList<>();
        String sql = "SELECT * FROM voiture";
        db.connect();
        try (Statement stmt = db.getConnection().createStatement();
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

    public Voiture getById(int id) {
        String sql = "SELECT * FROM voiture WHERE id = ?";
        db.connect();
        
        try (PreparedStatement stmt = db.getConnection().prepareStatement(sql)) {
            stmt.setInt(1, id);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return new Voiture(
                        rs.getInt("id"),
                        rs.getString("matricule"),
                        rs.getString("marque"),
                        rs.getString("model"),
                        rs.getInt("nombre_place"),
                        rs.getString("type_carburant")
                    );
                }
            }
        } catch (SQLException e) {
            System.out.println("Erreur lors de la récupération de la voiture : " + e.getMessage());
        }
        return null; 
    }
}