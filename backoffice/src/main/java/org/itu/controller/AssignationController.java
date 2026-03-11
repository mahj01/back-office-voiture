package org.itu.controller;

import java.sql.Date;
import java.util.List;

import org.itu.entity.AssignationVoiture;
import org.itu.util.AssignationService;
import org.itu.util.DB;
import org.itu.util.ErrorResponse;
import org.itu.util.TokenHandler;

import com.itu.ControllerAnnotation;
import com.itu.GetMapping;
import com.itu.JsonAnnotation;
import com.itu.ModelView;
import com.itu.PostMapping;
import com.itu.RequestParam;
import com.itu.UrlAnnotation;

import jakarta.servlet.http.HttpServletRequest;

@ControllerAnnotation(url = "assignation")
public class AssignationController {

    private DB openDb() {
        DB db = DB.fromEnv();
        db.connect();
        return db;
    }

    /**
     * Affiche le formulaire de saisie de date
     */
    @GetMapping
    @UrlAnnotation(url = "/saisie")
    public ModelView saisieDate() {
        ModelView mv = new ModelView("/assignation/saisieDate.jsp");
        return mv;
    }

    /**
     * Traite l'assignation et affiche les résultats
     */
    @PostMapping
    @UrlAnnotation(url = "/resultat")
    public ModelView resultatAssignation(@RequestParam("dateReservation") String dateStr) {
        ModelView mv = new ModelView("/assignation/resultatAssignation.jsp");

        DB db = openDb();
        try {
            Date date = Date.valueOf(dateStr);
            
            AssignationService service = new AssignationService(db);
            List<AssignationVoiture> assignations = service.assignerVoitures(date);
            double tempsAttente = service.getTempsAttenteMinutes();

            int totalReservations = 0;
            for (AssignationVoiture a : assignations) {
                totalReservations += a.getReservations().size();
            }

            mv.addAttribute("assignations", assignations);
            mv.addAttribute("dateReservation", dateStr);
            mv.addAttribute("nombreReservations", totalReservations);
            mv.addAttribute("nombreVoitures", assignations.size());
            mv.addAttribute("tempsAttente", tempsAttente);

            return mv;
        } catch (Exception e) {
            mv.addAttribute("error", "Erreur: " + e.getMessage());
            return mv;
        } finally {
            db.disconnect();
        }
    }

    /**
     * API JSON pour l'assignation
     */
    @JsonAnnotation
    @GetMapping
    @UrlAnnotation(url = "/api/{dateReservation}")
    public Object apiAssignation(@RequestParam("dateReservation") String dateStr, HttpServletRequest request) {
        String token = request.getHeader("X-Request-Token");

        if (!TokenHandler.isTokenValid(token)) {
            return new ErrorResponse(false, "Invalid or missing token");
        }

        DB db = openDb();
        try {
            Date date = Date.valueOf(dateStr);
            
            AssignationService service = new AssignationService(db);
            return service.assignerVoitures(date);
        } finally {
            db.disconnect();
        }
    }
}
