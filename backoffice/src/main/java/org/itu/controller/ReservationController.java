package org.itu.controller;

import java.sql.Date;
import java.util.List;

import org.itu.entity.Reservation;
import org.itu.util.DB;
import org.itu.util.FonctionReservation;

import com.itu.ControllerAnnotation;
import com.itu.GetMapping;
import com.itu.JsonAnnotation;
import com.itu.ModelView;
import com.itu.PostMapping;
import com.itu.RequestParam;
import com.itu.UrlAnnotation;

@ControllerAnnotation(url="reservation")
public class ReservationController {

    private static String host="localhost";
    private static String database="voiture_reservation";
    private static String user="app_dev";
    private static String password="dev_pwd";
    private static int port=5432;

    @JsonAnnotation
    @GetMapping
    @UrlAnnotation(url = "/liste")
    public List<Reservation> ListeReservation() {
        List<Reservation> allReservation;

        DB db = new DB(host, port, database, user, password);
        db.connect();
        FonctionReservation fc = new FonctionReservation(db);
        allReservation=fc.getAllReservations();

        return allReservation;
    }

    @JsonAnnotation
    @GetMapping
    @UrlAnnotation(url = "/liste/{dateArriver}")
    public List<Reservation> FilteByDate(@RequestParam("dateArriver") String dateArriverStr) {
        // Format attendu: yyyy-MM-dd (ex: 2026-02-06)
        Date dateArriver = Date.valueOf(dateArriverStr);
        
        DB db = new DB(host, port, database, user, password);
        db.connect();
        FonctionReservation fc = new FonctionReservation(db);
        List<Reservation> allReservation = fc.filterByDate(dateArriver);

        return allReservation;
    }


    @GetMapping
    @UrlAnnotation(url = "/saisie")
    public ModelView saisie() {
        ModelView mv = new ModelView("/createReservation.jsp");
        
        DB db = new DB(host, port, database, user, password);
        db.connect();
        FonctionReservation fc = new FonctionReservation(db);
        mv.addAttribute("hotels", fc.getAllHotels());
        
        return mv;
    }

    @PostMapping
    @UrlAnnotation(url = "/create")
    public ModelView createReservation(Reservation reservation) {
        ModelView mv = new ModelView("reservationSuccess.jsp");
        
        DB db = new DB(host, port, database, user, password);
        db.connect();
        reservation.connect(db);
        reservation.createReservation();
        
        mv.addAttribute("message", "Réservation créée avec succès");
        mv.addAttribute("reservation", reservation);
        
        return mv;
    }

}
