package org.itu.entity;

import java.sql.Date;

public class Reservation {
    private int id;
    private int idClient;
    private Date dateArriver;
    private int nombrePassager;
    private Hotel Hotel;

    public Reservation(int id, int idClient, Date dateArriver, int nombrePassager, Hotel hotel) {
        this.id = id;
        this.idClient = idClient;
        this.dateArriver = dateArriver;
        this.nombrePassager = nombrePassager;
        Hotel = hotel;
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
    public Date getDateArriver() {
        return dateArriver;
    }
    public void setDateArriver(Date dateArriver) {
        this.dateArriver = dateArriver;
    }
    public int getNombrePassager() {
        return nombrePassager;
    }
    public void setNombrePassager(int nombrePassager) {
        this.nombrePassager = nombrePassager;
    }
    public Hotel getHotel() {
        return Hotel;
    }
    public void setHotel(Hotel hotel) {
        Hotel = hotel;
    }


}
