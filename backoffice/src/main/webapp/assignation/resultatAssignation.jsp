<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="org.itu.entity.AssignationVoiture" %>
<%@ page import="org.itu.entity.Reservation" %>
<%@ page import="org.itu.entity.Voiture" %>
<%@ page import="org.itu.entity.Lieu" %>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Résultat des Assignations</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.0/font/bootstrap-icons.css" rel="stylesheet">
    <style>
        body { background-color: #f5f5f5; padding: 30px 0; }
        .voiture-card { border-left: 4px solid #0d6efd; }
        .voiture-card.no-voiture { border-left-color: #dc3545; }
        .itineraire-step { display: inline-flex; align-items: center; }
        .itineraire-arrow { margin: 0 6px; color: #6c757d; }
    </style>
</head>
<body>

<div class="container">
    <h2 class="text-center mb-4">
        <i class="bi bi-car-front-fill text-primary"></i> Résultat des Assignations
    </h2>

<%
    String error = (String) request.getAttribute("error");
    if (error != null) {
%>
    <div class="alert alert-danger">
        <i class="bi bi-exclamation-triangle"></i> <%= error %>
    </div>
<%
    }

    String dateReservation = (String) request.getAttribute("dateReservation");
    Integer nombreReservations = (Integer) request.getAttribute("nombreReservations");
    Integer nombreVoitures = (Integer) request.getAttribute("nombreVoitures");
    List<AssignationVoiture> assignations = (List<AssignationVoiture>) request.getAttribute("assignations");
%>

    <div class="alert alert-success text-center">
        <i class="bi bi-calendar-check"></i> <strong>Date :</strong> <%= dateReservation %> |
        <i class="bi bi-list-ol"></i> <strong>Réservations :</strong> <%= nombreReservations != null ? nombreReservations : 0 %> |
        <i class="bi bi-car-front"></i> <strong>Voitures utilisées :</strong> <%= nombreVoitures != null ? nombreVoitures : 0 %>
    </div>

<%
    if (assignations != null && !assignations.isEmpty()) {
        int voitureIndex = 1;
        for (AssignationVoiture assignation : assignations) {
            Voiture v = assignation.getVoiture();
            List<Reservation> groupReservations = assignation.getReservations();
            boolean isGrouped = assignation.isGrouped();
            boolean hasVoiture = v != null;
%>
    <!-- Carte Voiture #<%= voitureIndex %> -->
    <div class="card mb-4 shadow-sm voiture-card<%= !hasVoiture ? " no-voiture" : "" %>">
        <div class="card-header <%= hasVoiture ? "bg-primary" : "bg-danger" %> text-white d-flex justify-content-between align-items-center">
            <div>
                <i class="bi bi-car-front-fill"></i>
                <strong>Voiture #<%= voitureIndex %></strong>
                <% if (hasVoiture) { %>
                    &mdash; <%= v.getMarque() %> <%= v.getModele() %>
                    <span class="badge bg-light text-dark ms-2"><%= v.getMatricule() %></span>
                <% } else { %>
                    &mdash; <em>Aucune voiture disponible</em>
                <% } %>
            </div>
            <div>
                <% if (hasVoiture) { %>
                    <span class="badge bg-light text-dark">
                        <i class="bi bi-people-fill"></i> <%= assignation.getTotalPassagers() %>/<%= v.getNombrePlaces() %> places
                    </span>
                    <% if ("D".equals(v.getTypeCarburant())) { %>
                        <span class="badge bg-success ms-1"><i class="bi bi-droplet-fill"></i> Diesel</span>
                    <% } else if ("E".equals(v.getTypeCarburant())) { %>
                        <span class="badge bg-info ms-1"><i class="bi bi-fuel-pump"></i> Essence</span>
                    <% } else if ("G".equals(v.getTypeCarburant())) { %>
                        <span class="badge bg-warning text-dark ms-1"><i class="bi bi-droplet-half"></i> Gasoil</span>
                    <% } else { %>
                        <span class="badge bg-secondary ms-1"><%= v.getTypeCarburant() %></span>
                    <% } %>
                    <span class="badge bg-secondary ms-1">Écart: +<%= assignation.getEcartPlaces() %></span>
                <% } else { %>
                    <span class="badge bg-light text-danger"><i class="bi bi-x-circle"></i> Non assigné</span>
                <% } %>
            </div>
        </div>
        <div class="card-body">
            <!-- Réservations portées par cette voiture -->
            <h6 class="mb-3">
                <i class="bi bi-bookmark-fill text-primary"></i>
                Réservations (<%= groupReservations.size() %>)
                <% if (isGrouped) { %>
                    <span class="badge bg-info ms-1"><i class="bi bi-people-fill"></i> Regroupées</span>
                <% } %>
            </h6>
            <div class="table-responsive">
                <table class="table table-sm table-bordered table-hover mb-3">
                    <thead class="table-light">
                        <tr>
                            <th>#</th>
                            <th><i class="bi bi-person"></i> Client</th>
                            <th><i class="bi bi-people"></i> Passagers</th>
                            <th><i class="bi bi-geo-alt"></i> Lieu</th>
                            <th><i class="bi bi-clock"></i> Heure</th>
                        </tr>
                    </thead>
                    <tbody>
                    <%
                        int resIndex = 1;
                        for (Reservation r : groupReservations) {
                            Lieu l = r.getLieu();
                    %>
                        <tr>
                            <td><%= resIndex++ %></td>
                            <td>Client #<%= r.getIdClient() %></td>
                            <td><strong><%= r.getNombrePassager() %></strong></td>
                            <td><%= l != null ? l.getLibelle() : "N/A" %></td>
                            <td><%= r.getDateArriver() != null && r.getDateArriver().length() >= 16 ? r.getDateArriver().substring(11, 16) : "N/A" %></td>
                        </tr>
                    <%
                        }
                    %>
                    </tbody>
                </table>
            </div>

            <% if (hasVoiture) { %>
            <!-- Itinéraire / Trajet -->
            <div class="row">
                <div class="col-md-8">
                    <h6><i class="bi bi-signpost-split-fill text-success"></i> Itinéraire (trajet aller-retour)</h6>
                    <% if (assignation.getItineraire() != null && !assignation.getItineraire().isEmpty()) { %>
                        <div class="p-2 bg-light rounded mb-2">
                        <%
                            List<Lieu> itineraire = assignation.getItineraire();
                            for (int i = 0; i < itineraire.size(); i++) {
                                Lieu step = itineraire.get(i);
                                boolean isFirst = (i == 0);
                                boolean isLast = (i == itineraire.size() - 1);
                        %>
                            <span class="itineraire-step">
                                <% if (isFirst || isLast) { %>
                                    <span class="badge bg-danger"><i class="bi bi-airplane"></i> <%= step.getLibelle() %></span>
                                <% } else { %>
                                    <span class="badge bg-primary"><i class="bi bi-building"></i> <%= step.getLibelle() %></span>
                                <% } %>
                            </span>
                            <% if (!isLast) { %>
                                <span class="itineraire-arrow"><i class="bi bi-arrow-right"></i></span>
                            <% } %>
                        <%
                            }
                        %>
                        </div>
                    <% } else { %>
                        <span class="text-muted">Itinéraire non disponible</span>
                    <% } %>
                </div>
                <div class="col-md-4">
                    <h6><i class="bi bi-speedometer2 text-warning"></i> Résumé trajet</h6>
                    <ul class="list-unstyled mb-0">
                        <li>
                            <i class="bi bi-rulers"></i> Distance totale :
                            <% if (assignation.getDistanceTotaleKm() > 0) { %>
                                <span class="badge bg-primary"><%= assignation.getDistanceTotaleKm() %> km</span>
                            <% } else { %>
                                <span class="text-muted">N/A</span>
                            <% } %>
                        </li>
                        <li class="mt-1">
                            <i class="bi bi-clock-history"></i> Retour aéroport :
                            <% if (assignation.getHeureRetourAeroport() != null) { %>
                                <span class="badge bg-warning text-dark"><%= assignation.getHeureRetourAeroport() %></span>
                            <% } else { %>
                                <span class="text-muted">N/A</span>
                            <% } %>
                        </li>
                    </ul>
                </div>
            </div>
            <% } %>
        </div>
    </div>
<%
            voitureIndex++;
        }
    } else {
%>
    <div class="alert alert-warning">
        <i class="bi bi-exclamation-circle"></i> Aucune réservation trouvée pour cette date.
    </div>
<%
    }
%>

    <div class="text-center mt-4">
        <a href="saisie" class="btn btn-primary">
            <i class="bi bi-arrow-left"></i> Retour
        </a>
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
