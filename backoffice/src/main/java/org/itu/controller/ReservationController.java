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

    private DB openDb() {
        DB db = DB.fromEnv();
        db.connect();
        return db;
    }

    @JsonAnnotation
    @GetMapping
    @UrlAnnotation(url = "/liste")
    public List<Reservation> ListeReservation() {
        DB db = openDb();
        try {
            FonctionReservation fc = new FonctionReservation(db);
            return fc.getAllReservations();
        } finally {
            db.disconnect();
        }
    }

    @JsonAnnotation
    @GetMapping
    @UrlAnnotation(url = "/liste/{dateArriver}")
    public List<Reservation> FilteByDate(@RequestParam("dateArriver") String dateArriverStr) {
        // Format attendu: yyyy-MM-dd (ex: 2026-02-06)
        Date dateArriver = Date.valueOf(dateArriverStr);

        DB db = openDb();
        try {
            FonctionReservation fc = new FonctionReservation(db);
            return fc.filterByDate(dateArriver);
        } finally {
            db.disconnect();
        }
    }


    @GetMapping
    @UrlAnnotation(url = "/saisie")
    public ModelView saisie() {
        ModelView mv = new ModelView("/createReservation.jsp");

        DB db = openDb();
        try {
            FonctionReservation fc = new FonctionReservation(db);
            mv.addAttribute("hotels", fc.getAllHotels());
            return mv;
        } finally {
            db.disconnect();
        }
    }

    @PostMapping
    @UrlAnnotation(url = "/create")
    public ModelView createReservation(Reservation reservation) {
        ModelView mv = new ModelView("reservationSuccess.jsp");

        DB db = openDb();
        try {
            reservation.connect(db);
            reservation.createReservation();

            mv.addAttribute("message", "Réservation créée avec succès");
            mv.addAttribute("reservation", reservation);

            return mv;
        } finally {
            db.disconnect();
        }
    }

}
