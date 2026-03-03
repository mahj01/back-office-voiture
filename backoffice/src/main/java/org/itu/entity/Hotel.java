package org.itu.entity;

public class Hotel {
    public Hotel() {
    }

    public Hotel(String code , String libelle) {
        this.code = code;
        this.libelle = libelle;
    }


    public Hotel(Integer id, String libelle , String code) {
        this.id = id;
        this.libelle = libelle;
        this.code = code;
    }

    Integer id;
    String code;
    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
    }

    String libelle;

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getLibelle() {
        return libelle;
    }

    public void setLibelle(String libelle) {
        this.libelle = libelle;
    }
}
