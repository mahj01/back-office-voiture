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

    public Hotel(Integer id, String nom, String adresse) {
        this.id = id;
        this.nom = nom;
        this.adresse = adresse;
    }

    Integer id;
    String nom;
    String adresse;

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

    public String getAdresse() {
        return adresse;
    }

    public void setAdresse(String adresse) {
        this.adresse = adresse;
    }
}
