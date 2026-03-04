package org.itu.util;

import java.util.ArrayList;
import java.sql.Date;
import java.util.List;

import org.itu.entity.Lieu;
import org.itu.entity.Reservation;

public class FonctionReservation {
    private DB db;

    public FonctionReservation(DB db) {
        this.db = db;
    }

    public List<Reservation> getAllReservations() {
        List<Reservation> reservations = new ArrayList<>();
        String sql = "SELECT * FROM reservation";
        try (java.sql.Statement stmt = db.getConnection().createStatement();
                java.sql.ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                Reservation res = new Reservation(
                        rs.getInt("id"),
                        rs.getInt("idClient"),
                        rs.getTimestamp("dateArrivee"),
                        rs.getInt("nombrePassagers"),
                        this.getByIdLieu(rs.getInt("idLieu")));
                reservations.add(res);
            }
        } catch (java.sql.SQLException e) {
            System.out.println("Erreur lors de la récupération des réservations : " + e.getMessage());
        }
        return reservations;
    }

    public Lieu getByIdLieu(int id) {
        String sql = "SELECT * FROM lieu WHERE id = ?";
        try (java.sql.PreparedStatement stmt = db.getConnection().prepareStatement(sql)) {
            stmt.setInt(1, id);
            try (java.sql.ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return new Lieu(
                            rs.getInt("id"),
                            rs.getString("code"),
                            rs.getString("libelle"),
                            rs.getString("type_lieu"));
                }
            }
        } catch (java.sql.SQLException e) {
            System.out.println("Erreur lors de la récupération du lieu : " + e.getMessage());
        }
        return null;
    }

    public List<Lieu> getAllLieux() {
        List<Lieu> lieux = new ArrayList<>();
        String sql = "SELECT * FROM lieu";
        try (java.sql.Statement stmt = db.getConnection().createStatement();
                java.sql.ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                Lieu lieu = new Lieu(
                        rs.getInt("id"),
                        rs.getString("code"),
                        rs.getString("libelle"),
                        rs.getString("type_lieu"));
                lieux.add(lieu);
            }
        } catch (java.sql.SQLException e) {
            System.out.println("Erreur lors de la récupération des lieux : " + e.getMessage());
        }
        return lieux;
    }

    public List<Reservation> filterByDate(Date dateArriver) {
        String sql = "SELECT * FROM reservation WHERE DATE(dateArrivee) = ?";
        List<Reservation> reponse = new ArrayList<>();
        try (java.sql.PreparedStatement stmt = db.getConnection().prepareStatement(sql)) {
            stmt.setDate(1, dateArriver);
            try (java.sql.ResultSet rs = stmt.executeQuery()) {

                while (rs.next()) {

                    Reservation r = new Reservation(
                            rs.getInt("id"),
                            rs.getInt("idClient"),
                            rs.getTimestamp("dateArrivee"),
                            rs.getInt("nombrePassagers"),
                            this.getByIdLieu(rs.getInt("idLieu")));
                    reponse.add(r);
                }
            }
        } catch (java.sql.SQLException e) {
            System.out.println("Erreur lors de la récupération du lieu : " + e.getMessage());
        }
        return reponse;
    }

}
