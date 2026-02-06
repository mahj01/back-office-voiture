package org.itu.entity;

public class Hotel {
    public Hotel() {
    }

    public Hotel(String nom) {
        this.nom = nom;
    }


    public Hotel(Integer id, String nom) {
        this.id = id;
        this.nom = nom;
    }

    Integer id;
    String nom;

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getNom() {
        return nom;
    }

    public void setNom(String nom) {
        this.nom = nom;
    }
}
