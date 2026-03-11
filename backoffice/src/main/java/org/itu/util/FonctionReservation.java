package org.itu.util;

import java.sql.Date;
import java.util.ArrayList;
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
        String sql = "SELECT r.*, la.id as aero_id, la.code as aero_code, la.libelle as aero_libelle, la.type_lieu as aero_type " +
                     "FROM reservation r " +
                     "LEFT JOIN lieu la ON r.idlieuatterissage = la.id";
        try (java.sql.Statement stmt = db.getConnection().createStatement();
                java.sql.ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                Lieu aero = buildLieuAtterissage(rs);
                Reservation res = new Reservation(
                        rs.getInt("id"),
                        rs.getInt("idClient"),
                        rs.getTimestamp("dateArrivee"),
                        rs.getInt("nombrePassagers"),
                        this.getByIdLieu(rs.getInt("idLieu")),
                        aero);
                reservations.add(res);
            }
        } catch (java.sql.SQLException e) {
            System.out.println("Erreur lors de la récupération des réservations : " + e.getMessage());
        }
        return reservations;
    }

    /** Construit le Lieu atterissage à partir du ResultSet courant (colonnes aero_*) */
    private Lieu buildLieuAtterissage(java.sql.ResultSet rs) throws java.sql.SQLException {
        if (rs.getObject("aero_id") != null) {
            return new Lieu(rs.getInt("aero_id"), rs.getString("aero_code"),
                            rs.getString("aero_libelle"), rs.getString("aero_type"));
        }
        return null;
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
        String sql = "SELECT r.*, la.id as aero_id, la.code as aero_code, la.libelle as aero_libelle, la.type_lieu as aero_type " +
                     "FROM reservation r " +
                     "LEFT JOIN lieu la ON r.idlieuatterissage = la.id " +
                     "WHERE DATE(r.dateArrivee) = ?";
        List<Reservation> reponse = new ArrayList<>();
        try (java.sql.PreparedStatement stmt = db.getConnection().prepareStatement(sql)) {
            stmt.setDate(1, dateArriver);
            try (java.sql.ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Lieu aero = buildLieuAtterissage(rs);
                    Reservation r = new Reservation(
                            rs.getInt("id"),
                            rs.getInt("idClient"),
                            rs.getTimestamp("dateArrivee"),
                            rs.getInt("nombrePassagers"),
                            this.getByIdLieu(rs.getInt("idLieu")),
                            aero);
                    reponse.add(r);
                }
            }
        } catch (java.sql.SQLException e) {
            System.out.println("Erreur lors de la récupération du lieu : " + e.getMessage());
        }
        return reponse;
    }

    /** Retourne uniquement les lieux de type AEROPORT */
    public List<Lieu> getAllAeroports() {
        List<Lieu> aeroports = new ArrayList<>();
        String sql = "SELECT l.* FROM lieu l " +
                     "JOIN type_lieu tl ON CAST(l.type_lieu AS INTEGER) = tl.id " +
                     "WHERE tl.libelle = 'AEROPORT' ORDER BY l.libelle";
        try (java.sql.Statement stmt = db.getConnection().createStatement();
                java.sql.ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                aeroports.add(new Lieu(rs.getInt("id"), rs.getString("code"),
                                      rs.getString("libelle"), rs.getString("type_lieu")));
            }
        } catch (java.sql.SQLException e) {
            System.out.println("Erreur getAllAeroports : " + e.getMessage());
        }
        return aeroports;
    }

}
