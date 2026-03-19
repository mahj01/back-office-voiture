package org.itu.entity;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Classe représentant l'assignation d'une voiture à une réservation
 * Supporte la séparation des passagers d'un client entre plusieurs voitures
 */
public class AssignationVoiture {
    private Reservation reservation;
    private Voiture voiture;
    private int ecartPlaces; // nombre_place - total passagers du groupe
    private List<Reservation> reservations; // toutes les réservations assignées à cette voiture
    private Map<Integer, Integer> passagersParReservation; // nb passagers assignés par réservation (clé = ID réservation)
    private List<Lieu> lieux; // tous les lieux du groupe
    private List<Lieu> itineraire; // itinéraire ordonné (aéroport -> hotels -> aéroport)
    private List<Double> distancesParEtape; // distance de chaque tronçon (index i = step[i]→step[i+1])
    private double distanceTotaleKm; // distance totale aller-retour en km
    private String heureRetourAeroport; // heure estimée de retour à l'aéroport
    private double vitesseKmH;       // vitesse utilisée pour le calcul (km/h)
    private double tempAttenteMin;   // temps d'attente par arrêt intermédiaire (min)
    private long tempsTrajetMinutes; // durée totale du trajet (conduite + attente) en min

    public AssignationVoiture() {
        this.reservations = new ArrayList<>();
        this.passagersParReservation = new LinkedHashMap<>();
        this.lieux = new ArrayList<>();
        this.itineraire = new ArrayList<>();
        this.distancesParEtape = new ArrayList<>();
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
        this.passagersParReservation.put(r.getId(), r.getNombrePassager());
        if (r.getLieu() != null) {
            this.lieux.add(r.getLieu());
        }
        calculateEcart();
    }

    /**
     * Ajoute une réservation avec un nombre spécifique de passagers (séparation)
     * @param r La réservation
     * @param nombrePassagers Le nombre de passagers assignés à cette voiture
     */
    public void addReservationPartielle(Reservation r, int nombrePassagers) {
        // Si la réservation est déjà dans la liste, mettre à jour le nombre de passagers
        if (passagersParReservation.containsKey(r.getId())) {
            passagersParReservation.put(r.getId(), passagersParReservation.get(r.getId()) + nombrePassagers);
        } else {
            this.reservations.add(r);
            this.passagersParReservation.put(r.getId(), nombrePassagers);
            if (r.getLieu() != null) {
                this.lieux.add(r.getLieu());
            }
        }
        calculateEcart();
    }

    /**
     * Retourne le nombre de passagers assignés pour une réservation spécifique
     */
    public int getPassagersAssignes(Reservation r) {
        return passagersParReservation.getOrDefault(r.getId(), 0);
    }

    /**
     * Retourne le map des passagers par réservation
     */
    public Map<Integer, Integer> getPassagersParReservation() {
        return passagersParReservation;
    }

    /**
     * Retourne le nombre total de passagers de toutes les réservations du groupe
     */
    public int getTotalPassagers() {
        int total = 0;
        for (Integer passagers : passagersParReservation.values()) {
            total += passagers;
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

    public List<Double> getDistancesParEtape() {
        return distancesParEtape;
    }

    public void setDistancesParEtape(List<Double> distancesParEtape) {
        this.distancesParEtape = distancesParEtape;
    }

    public double getVitesseKmH() {
        return vitesseKmH;
    }

    public void setVitesseKmH(double vitesseKmH) {
        this.vitesseKmH = vitesseKmH;
    }

    public double getTempAttenteMin() {
        return tempAttenteMin;
    }

    public void setTempAttenteMin(double tempAttenteMin) {
        this.tempAttenteMin = tempAttenteMin;
    }

    public long getTempsTrajetMinutes() {
        return tempsTrajetMinutes;
    }

    public void setTempsTrajetMinutes(long tempsTrajetMinutes) {
        this.tempsTrajetMinutes = tempsTrajetMinutes;
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
