package org.itu.entity;

public class Lieu {
    private Integer id;
    private String code;
    private String libelle;
    private String typeLieu;

    public Lieu() {
    }

    public Lieu(String code, String libelle, String typeLieu) {
        this.code = code;
        this.libelle = libelle;
        this.typeLieu = typeLieu;
    }

    public Lieu(Integer id, String code, String libelle, String typeLieu) {
        this.id = id;
        this.code = code;
        this.libelle = libelle;
        this.typeLieu = typeLieu;
    }

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
    }

    public String getLibelle() {
        return libelle;
    }

    public void setLibelle(String libelle) {
        this.libelle = libelle;
    }

    public String getTypeLieu() {
        return typeLieu;
    }

    public void setTypeLieu(String typeLieu) {
        this.typeLieu = typeLieu;
    }
}
