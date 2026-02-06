package org.itu.entity;

import java.sql.Timestamp;

import org.itu.util.DB;

public class Reservation {
    private int id;
    private int idClient;
    private String dateArriver;
    private int nombrePassager;
    private int idHotel;
    private Hotel hotel;

    private DB db;

    public Reservation() {
    }

    public Reservation(int id, int idClient, Timestamp dateArriver, int nombrePassager, Hotel hotel) {
        this.id = id;
        this.idClient = idClient;
        if (dateArriver != null) {
            this.dateArriver = dateArriver.toString();
        }
        this.nombrePassager = nombrePassager;
        this.hotel = hotel;
        if (hotel != null) {
            this.idHotel = hotel.getId();
        }
    }
    
    public int getId() {
        return id;
    }
    public void setId(int id) {
        this.id = id;
    }
    public int getIdClient() {
        return idClient;
    }
    public void setIdClient(int idClient) {
        this.idClient = idClient;
    }
    public String getDateArriver() {
        return dateArriver;
    }
    public void setDateArriver(String dateArriver) {
        this.dateArriver = dateArriver;
    }
    public Timestamp getDateArriverAsTimestamp() {
        if (dateArriver != null && !dateArriver.isEmpty()) {
            String formatted = dateArriver.replace("T", " ");
            if (!formatted.contains(":") || formatted.split(":").length < 3) {
                formatted += ":00";
            }
            return Timestamp.valueOf(formatted);
        }
        return null;
    }
    public int getNombrePassager() {
        return nombrePassager;
    }
    public void setNombrePassager(int nombrePassager) {
        this.nombrePassager = nombrePassager;
    }
    public int getIdHotel() {
        return idHotel;
    }
    public void setIdHotel(int idHotel) {
        this.idHotel = idHotel;
    }
    public Hotel getHotel() {
        return hotel;
    }
    public void setHotel(Hotel hotel) {
        this.hotel = hotel;
        if (hotel != null) {
            this.idHotel = hotel.getId();
        }
    }

    public void connect(DB db)
    {
        this.db = db;
    }

    public void delete() {
        String sql = "DELETE FROM reservation WHERE id = ?";
        try (java.sql.PreparedStatement stmt = db.getConnection().prepareStatement(sql)) {
            stmt.setInt(1, this.id);
            stmt.executeUpdate();
            System.out.println("Réservation supprimée avec succès.");
        } catch (java.sql.SQLException e) {
            System.out.println("Erreur lors de la suppression de la réservation : " + e.getMessage());
        }
    }

    public void createReservation() {
        String sql = "INSERT INTO reservation (idClient, idHotel, dateArrivee, nombrePassagers) VALUES (?, ?, ?, ?)";
        try (java.sql.PreparedStatement stmt = db.getConnection().prepareStatement(sql)) {
            stmt.setInt(1, this.idClient);
            stmt.setInt(2, this.idHotel);
            stmt.setTimestamp(3, this.getDateArriverAsTimestamp());
            stmt.setInt(4, this.nombrePassager);
            stmt.executeUpdate();
            System.out.println("Réservation créée avec succès.");
        } catch (java.sql.SQLException e) {
            System.out.println("Erreur lors de la création de la réservation : " + e.getMessage());
        }
    }
}
