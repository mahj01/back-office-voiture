package org.itu.controller;

import java.io.IOException;
import java.util.List;

import org.itu.entity.Voiture;
import org.itu.util.DB;
import org.itu.util.FonctionVoiture;

import com.itu.ControllerAnnotation;
import com.itu.GetMapping;
import com.itu.ModelView;
import com.itu.PostMapping;
import com.itu.RequestParam;
import com.itu.UrlAnnotation;

import jakarta.servlet.http.HttpServletResponse;

@ControllerAnnotation(url="voiture")
public class VoitureController {
    private DB openDb() {
        DB db = DB.fromEnv();
        db.connect();
        return db;
    }

    @GetMapping
    @UrlAnnotation(url = "/")
    public void liste(HttpServletResponse response) throws IOException {
        response.sendRedirect("voiture/liste");
    }
    
    @GetMapping
    @UrlAnnotation(url = "/liste")
    public ModelView ListeVoiture() {
        DB db = openDb();
        ModelView mv = new ModelView("/voiture/voitureList.jsp");
        try {
            FonctionVoiture fc = new FonctionVoiture(db);
            List<Voiture> voitures = fc.getAllVoitures();
            System.out.println("DEBUG: voitures count=" + (voitures == null ? 0 : voitures.size()));
            mv.addAttribute("voitures", voitures);
            
        } finally {
            db.disconnect();
        }
        return mv;
    }

    @GetMapping
    @UrlAnnotation(url = "/saisie")
    public ModelView saisie() {
        ModelView mv = new ModelView("/voiture/createVoiture.jsp");
        return mv;
    }

    @PostMapping
    @UrlAnnotation(url = "/create")
    public ModelView createVoiture(Voiture voiture) {
        ModelView mv = new ModelView("/voiture/voitureSuccess.jsp");

        DB db = openDb();
        try {
            voiture.connectDB(db);
            voiture.createVoiture();

            mv.addAttribute("message", "Voiture créée avec succès");
            mv.addAttribute("voiture", voiture);
            return mv;
        } finally {
            db.disconnect();
        }
    }

    @GetMapping
    @UrlAnnotation(url = "/edit/{id}")
    public ModelView editVoiture(@RequestParam("id") int id) {
        ModelView mv = new ModelView("/voiture/editVoiture.jsp");
        FonctionVoiture fc = new FonctionVoiture(openDb());
        Voiture vt = fc.getById(id);
        mv.addAttribute("voiture", vt);
        mv.addAttribute("id", id);
        return mv;
    }

    @GetMapping
    @UrlAnnotation(url = "/view/{id}")
    public ModelView viewVoiture(@RequestParam("id") int id) {
        ModelView mv = new ModelView("/voiture/viewVoiture.jsp");
        FonctionVoiture fc = new FonctionVoiture(openDb());
        Voiture vt = fc.getById(id);
        mv.addAttribute("voiture", vt);
        mv.addAttribute("id", id);
        return mv;
    }


    @PostMapping
    @UrlAnnotation(url = "/update")
    public ModelView updateVoiture(@RequestParam("id") int id, Voiture voiture) {
        ModelView mv = new ModelView("/voiture/voitureSuccess.jsp");

        DB db = openDb();
        try {
            voiture.setId(id);
            voiture.connectDB(db);
            voiture.updateVoiture();

            mv.addAttribute("message", "Voiture mise à jour avec succès");
            mv.addAttribute("voiture", voiture);
            return mv;
        } finally {
            db.disconnect();
        }
    }

    @GetMapping
    @UrlAnnotation(url = "/delete/{id}")
    public ModelView deleteVoiture(@RequestParam("id") int id) {
        ModelView mv = new ModelView("/voiture/voitureSuccess.jsp");   
         DB db = openDb();
        try {
            FonctionVoiture fc = new FonctionVoiture(db);
            Voiture vt = fc.getById(id);
            if (vt != null) {
                vt.connectDB(db);
                vt.delete();
                mv.addAttribute("message", "Voiture supprimée avec succès");
            } else {
                mv.addAttribute("message", "Voiture non trouvée");
            }
            return mv;
        } finally {
            db.disconnect();
        }
    }

}
