package org.itu;

public class Employe {
    private String nom;
    private String departement;

    public String getNom() {
        return nom;
    }

    public void setNom(String nom) {
        this.nom = nom;
    }

    public String getDepartement() {
        return departement;
    }

    public void setDepartement(String departement) {
        this.departement = departement;
    }

    public Employe(String nom, String departement) {
        this.nom = nom;
        this.departement = departement;
    }

    public Employe() {
    }
}
