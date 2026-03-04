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
    <!-- Bootstrap CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Bootstrap Icons -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.0/font/bootstrap-icons.css" rel="stylesheet">
    <style>
        body {
            background-color: #f5f5f5;
            padding: 30px 0;
        }
    </style>
</head>
<body>

<div class="container">
    <h2 class="text-center mb-4">
        <i class="bi bi-car-front-fill text-primary"></i> 
        Résultat des Assignations
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
%>

<%
    String dateReservation = (String) request.getAttribute("dateReservation");
    Integer nombreReservations = (Integer) request.getAttribute("nombreReservations");
    List<AssignationVoiture> assignations = (List<AssignationVoiture>) request.getAttribute("assignations");
%>

    <div class="alert alert-success text-center">
        <i class="bi bi-calendar-check"></i> <strong>Date :</strong> <%= dateReservation %> | 
        <i class="bi bi-list-ol"></i> <strong>Nombre de réservations :</strong> <%= nombreReservations != null ? nombreReservations : 0 %>
    </div>

<%
    if (assignations != null && !assignations.isEmpty()) {
%>
    <div class="table-responsive">
        <table class="table table-striped table-hover">
            <thead class="table-dark">
                <tr>
                    <th>#</th>
                    <th><i class="bi bi-person"></i> Client</th>
                    <th><i class="bi bi-people"></i> Passagers</th>
                    <th><i class="bi bi-geo-alt"></i> Lieu</th>
                    <th><i class="bi bi-clock"></i> Heure</th>
                    <th><i class="bi bi-car-front"></i> Voiture</th>
                    <th><i class="bi bi-card-text"></i> Matricule</th>
                    <th><i class="bi bi-hash"></i> Places</th>
                    <th><i class="bi bi-fuel-pump"></i> Carburant</th>
                    <th><i class="bi bi-plus-slash-minus"></i> Écart</th>
                    <th><i class="bi bi-signpost-split"></i> Itinéraire</th>
                    <th><i class="bi bi-speedometer2"></i> Distance</th>
                    <th><i class="bi bi-clock-history"></i> Retour Aéroport</th>
                    <th><i class="bi bi-check-circle"></i> Statut</th>
                </tr>
            </thead>
            <tbody>
    <%
        int index = 1;
        for (AssignationVoiture assignation : assignations) {
            java.util.List<Reservation> groupReservations = assignation.getReservations();
            Voiture v = assignation.getVoiture();
            int groupSize = groupReservations.size();
            boolean isGrouped = assignation.isGrouped();
            
            for (int i = 0; i < groupSize; i++) {
                Reservation r = groupReservations.get(i);
                Lieu l = r.getLieu();
    %>
            <tr<%= isGrouped ? " class=\"table-info\"" : "" %>>
                <% if (i == 0) { %><td rowspan="<%= groupSize %>"><%= index++ %></td><% } %>
                <td>Client #<%= r.getIdClient() %></td>
                <td><strong><%= r.getNombrePassager() %></strong></td>
                <td><%= l != null ? l.getLibelle() : "N/A" %></td>
                <td><%= r.getDateArriver() != null ? r.getDateArriver().substring(11, 16) : "N/A" %></td>
                
                <% if (i == 0) { %>
                    <% if (v != null) { %>
                        <td rowspan="<%= groupSize %>"><%= v.getMarque() %> <%= v.getModele() %></td>
                        <td rowspan="<%= groupSize %>"><strong><%= v.getMatricule() %></strong></td>
                        <td rowspan="<%= groupSize %>"><%= v.getNombrePlaces() %></td>
                        <td rowspan="<%= groupSize %>">
                            <% if ("D".equals(v.getTypeCarburant())) { %>
                                <span class="text-success fw-bold">
                                    <i class="bi bi-droplet-fill"></i> Diesel
                                </span>
                            <% } else if ("G".equals(v.getTypeCarburant())) { %>
                                <span class="text-warning fw-bold">
                                    <i class="bi bi-droplet-half"></i> Gasoil
                                </span>
                            <% } else if ("E".equals(v.getTypeCarburant())) { %>
                                <span class="text-info fw-bold">
                                    <i class="bi bi-fuel-pump"></i> Essence
                                </span>
                            <% } else { %>
                                <%= v.getTypeCarburant() %>
                            <% } %>
                        </td>
                        <td rowspan="<%= groupSize %>"><span class="badge bg-secondary">+<%= assignation.getEcartPlaces() %></span></td>
                        <td rowspan="<%= groupSize %>">
                            <% if (assignation.getItineraire() != null && !assignation.getItineraire().isEmpty()) { %>
                                <small><%= assignation.getItineraireStr() %></small>
                            <% } else { %>
                                <span class="text-muted">N/A</span>
                            <% } %>
                        </td>
                        <td rowspan="<%= groupSize %>">
                            <% if (assignation.getDistanceTotaleKm() > 0) { %>
                                <span class="badge bg-primary"><%= assignation.getDistanceTotaleKm() %> km</span>
                            <% } else { %>
                                <span class="text-muted">N/A</span>
                            <% } %>
                        </td>
                        <td rowspan="<%= groupSize %>">
                            <% if (assignation.getHeureRetourAeroport() != null) { %>
                                <span class="badge bg-warning text-dark"><i class="bi bi-clock-history"></i> <%= assignation.getHeureRetourAeroport() %></span>
                            <% } else { %>
                                <span class="text-muted">N/A</span>
                            <% } %>
                        </td>
                        <td rowspan="<%= groupSize %>">
                            <span class="badge bg-success"><i class="bi bi-check-lg"></i> Assigné</span>
                            <% if (isGrouped) { %>
                                <br><span class="badge bg-info mt-1"><i class="bi bi-people-fill"></i> Groupe (<%= assignation.getTotalPassagers() %> pass.)</span>
                                <br><small class="text-muted"><i class="bi bi-geo-alt-fill"></i> Lieux:
                                <% for (int li = 0; li < assignation.getLieux().size(); li++) { %>
                                    <%= assignation.getLieux().get(li).getLibelle() %><%= li < assignation.getLieux().size() - 1 ? ", " : "" %>
                                <% } %>
                                </small>
                            <% } %>
                        </td>
                    <% } else { %>
                        <td rowspan="<%= groupSize %>" colspan="8" class="text-danger fw-bold">
                            <i class="bi bi-x-circle"></i> Aucune voiture disponible
                        </td>
                        <td rowspan="<%= groupSize %>"><span class="badge bg-danger"><i class="bi bi-x-lg"></i> Non assigné</span></td>
                    <% } %>
                <% } %>
            </tr>
    <%
            }
        }
    %>
            </tbody>
        </table>
    </div>
<%
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

<!-- Bootstrap JS -->
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
