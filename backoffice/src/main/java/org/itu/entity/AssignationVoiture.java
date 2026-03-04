package org.itu.entity;

import java.util.ArrayList;
import java.util.List;

/**
 * Classe représentant l'assignation d'une voiture à une réservation
 */
public class AssignationVoiture {
    private Reservation reservation;
    private Voiture voiture;
    private int ecartPlaces; // nombre_place - total passagers du groupe
    private List<Reservation> reservations; // toutes les réservations assignées à cette voiture
    private List<Lieu> lieux; // tous les lieux du groupe
    private List<Lieu> itineraire; // itinéraire ordonné (aéroport -> hotels -> aéroport)
    private double distanceTotaleKm; // distance totale du trajet en km
    private String heureRetourAeroport; // heure estimée de retour à l'aéroport

    public AssignationVoiture() {
        this.reservations = new ArrayList<>();
        this.lieux = new ArrayList<>();
        this.itineraire = new ArrayList<>();
    }

    public AssignationVoiture(Reservation reservation, Voiture voiture) {
        this();
        this.reservation = reservation;
        this.voiture = voiture;
        if (reservation != null) {
            this.reservations.add(reservation);
            if (reservation.getLieu() != null) {
                this.lieux.add(reservation.getLieu());
            }
        }
        calculateEcart();
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

    public List<Reservation> getReservations() {
        return reservations;
    }

    public void setReservations(List<Reservation> reservations) {
        this.reservations = reservations;
    }

    public List<Lieu> getLieux() {
        return lieux;
    }

    public void setLieux(List<Lieu> lieux) {
        this.lieux = lieux;
    }

    /**
     * Ajoute une réservation au groupe et met à jour les lieux
     */
    public void addReservation(Reservation r) {
        this.reservations.add(r);
        if (r.getLieu() != null) {
            this.lieux.add(r.getLieu());
        }
        calculateEcart();
    }

    /**
     * Retourne le nombre total de passagers de toutes les réservations du groupe
     */
    public int getTotalPassagers() {
        int total = 0;
        for (Reservation r : reservations) {
            total += r.getNombrePassager();
        }
        return total;
    }

    /**
     * Indique si ce groupe contient plusieurs réservations
     */
    public boolean isGrouped() {
        return reservations.size() > 1;
    }

    public List<Lieu> getItineraire() {
        return itineraire;
    }

    public void setItineraire(List<Lieu> itineraire) {
        this.itineraire = itineraire;
    }

    public double getDistanceTotaleKm() {
        return distanceTotaleKm;
    }

    public void setDistanceTotaleKm(double distanceTotaleKm) {
        this.distanceTotaleKm = distanceTotaleKm;
    }

    public String getHeureRetourAeroport() {
        return heureRetourAeroport;
    }

    public void setHeureRetourAeroport(String heureRetourAeroport) {
        this.heureRetourAeroport = heureRetourAeroport;
    }

    /**
     * Retourne l'itinéraire sous forme de chaîne lisible
     */
    public String getItineraireStr() {
        if (itineraire == null || itineraire.isEmpty()) return "";
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < itineraire.size(); i++) {
            sb.append(itineraire.get(i).getLibelle());
            if (i < itineraire.size() - 1) sb.append(" → ");
        }
        return sb.toString();
    }

    private void calculateEcart() {
        if (voiture != null && !reservations.isEmpty()) {
            this.ecartPlaces = voiture.getNombrePlaces() - getTotalPassagers();
        } else if (voiture != null && reservation != null) {
            this.ecartPlaces = voiture.getNombrePlaces() - reservation.getNombrePassager();
        }
    }

    public boolean hasVoiture() {
        return voiture != null;
    }
}
