package org.itu.entity;

public class Distance {
    private Integer id;
    private Integer fromLieuId;
    private Integer toLieuId;
    private Double km;
    
    // Relations
    private Lieu fromLieu;
    private Lieu toLieu;

    public Distance() {
    }

    public Distance(Integer fromLieuId, Integer toLieuId, Double km) {
        this.fromLieuId = fromLieuId;
        this.toLieuId = toLieuId;
        this.km = km;
    }

    public Distance(Integer id, Integer fromLieuId, Integer toLieuId, Double km) {
        this.id = id;
        this.fromLieuId = fromLieuId;
        this.toLieuId = toLieuId;
        this.km = km;
    }

    public Distance(Integer id, Lieu fromLieu, Lieu toLieu, Double km) {
        this.id = id;
        this.fromLieu = fromLieu;
        this.toLieu = toLieu;
        if (fromLieu != null) {
            this.fromLieuId = fromLieu.getId();
        }
        if (toLieu != null) {
            this.toLieuId = toLieu.getId();
        }
        this.km = km;
    }

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public Integer getFromLieuId() {
        return fromLieuId;
    }

    public void setFromLieuId(Integer fromLieuId) {
        this.fromLieuId = fromLieuId;
    }

    public Integer getToLieuId() {
        return toLieuId;
    }

    public void setToLieuId(Integer toLieuId) {
        this.toLieuId = toLieuId;
    }

    public Double getKm() {
        return km;
    }

    public void setKm(Double km) {
        this.km = km;
    }

    public Lieu getFromLieu() {
        return fromLieu;
    }

    public void setFromLieu(Lieu fromLieu) {
        this.fromLieu = fromLieu;
        if (fromLieu != null) {
            this.fromLieuId = fromLieu.getId();
        }
    }

    public Lieu getToLieu() {
        return toLieu;
    }

    public void setToLieu(Lieu toLieu) {
        this.toLieu = toLieu;
        if (toLieu != null) {
            this.toLieuId = toLieu.getId();
        }
    }
}
