package org.itu.entity;

/**
 * Entité représentant un type de lieu (AEROPORT, HOTEL, GARE, etc.)
 */
public class TypeLieu {
    private Integer id;
    private String libelle;

    public TypeLieu() {
    }

    public TypeLieu(String libelle) {
        this.libelle = libelle;
    }

    public TypeLieu(Integer id, String libelle) {
        this.id = id;
        this.libelle = libelle;
    }

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
