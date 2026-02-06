package org.itu.util;

import java.sql.Date;
import java.util.ArrayList;
import java.util.List;

import org.itu.entity.Hotel;
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
                    this.getByIdHotel(rs.getInt("idHotel"))
                );
                reservations.add(res);
            }
        } catch (java.sql.SQLException e) {
            System.out.println("Erreur lors de la récupération des réservations : " + e.getMessage());
        }
        return reservations;
    }

    public Hotel getByIdHotel(int id)
    {
        String sql = "SELECT * FROM hotel WHERE id = ?";
        try (java.sql.PreparedStatement stmt = db.getConnection().prepareStatement(sql)) {
            stmt.setInt(1, id);
            try (java.sql.ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return new Hotel(
                        rs.getInt("id"),
                        rs.getString("nom")
                    );
                }
            }
        } catch (java.sql.SQLException e) {
            System.out.println("Erreur lors de la récupération de l'hôtel : " + e.getMessage());
        }
        return null; 
    }

    public List<Hotel> getAllHotels() {
        List<Hotel> hotels = new ArrayList<>();
        String sql = "SELECT * FROM hotel";
        try (java.sql.Statement stmt = db.getConnection().createStatement();
             java.sql.ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                Hotel hotel = new Hotel(
                    rs.getInt("id"),
                    rs.getString("nom")
                );
                hotels.add(hotel);
            }
        } catch (java.sql.SQLException e) {
            System.out.println("Erreur lors de la récupération des hôtels : " + e.getMessage());
        }
        return hotels;
    }

    public List<Reservation> filterByDate(Date dateArriver)
    {
        String sql = "SELECT * FROM reservation WHERE DATE(dateArrivee) = ?";
        List<Reservation> reponse = new  ArrayList<>();
        try (java.sql.PreparedStatement stmt = db.getConnection().prepareStatement(sql)) {
            stmt.setDate(1, dateArriver);
            try (java.sql.ResultSet rs = stmt.executeQuery()) {
            
                while (rs.next()) {
                    
                    Reservation r =  new Reservation(
                        rs.getInt("id"),
                        rs.getInt("idClient"),
                        rs.getTimestamp("dateArrivee"),
                        rs.getInt("nombrePassagers"),
                        this.getByIdHotel(rs.getInt("idHotel"))
                    );
                    reponse.add(r);
                }
            }
        } catch (java.sql.SQLException e) {
            System.out.println("Erreur lors de la récupération de l'hôtel : " + e.getMessage());
        }
        return reponse; 
    }

}
