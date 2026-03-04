package org.itu.entity;

/**
 * Classe représentant l'assignation d'une voiture à une réservation
 */
public class AssignationVoiture {
    private Reservation reservation;
    private Voiture voiture;
    private int ecartPlaces; // nombre_place - nombrePassagers

    public AssignationVoiture() {
    }

    public AssignationVoiture(Reservation reservation, Voiture voiture) {
        this.reservation = reservation;
        this.voiture = voiture;
        if (voiture != null && reservation != null) {
            this.ecartPlaces = voiture.getNombrePlaces() - reservation.getNombrePassager();
        }
    }

    public Reservation getReservation() {
        return reservation;
    }

    public void setReservation(Reservation reservation) {
        this.reservation = reservation;
        calculateEcart();
    }

    public Voiture getVoiture() {
        return voiture;
    }

    public void setVoiture(Voiture voiture) {
        this.voiture = voiture;
        calculateEcart();
    }

    public int getEcartPlaces() {
        return ecartPlaces;
    }

    public void setEcartPlaces(int ecartPlaces) {
        this.ecartPlaces = ecartPlaces;
    }

    private void calculateEcart() {
        if (voiture != null && reservation != null) {
            this.ecartPlaces = voiture.getNombrePlaces() - reservation.getNombrePassager();
        }
    }

    public boolean hasVoiture() {
        return voiture != null;
    }
}
