package org.itu.entity;

public class Parametre {
    private Integer id;
    private String libelle;
    private String valeur;

    public Parametre() {
    }

    public Parametre(String libelle, String valeur) {
        this.libelle = libelle;
        this.valeur = valeur;
    }

    public Parametre(Integer id, String libelle, String valeur) {
        this.id = id;
        this.libelle = libelle;
        this.valeur = valeur;
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

    public String getValeur() {
        return valeur;
    }

    public void setValeur(String valeur) {
        this.valeur = valeur;
    }
}
