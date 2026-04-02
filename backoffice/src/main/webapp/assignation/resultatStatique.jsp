<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.io.*" %>
<%@ page import="com.fasterxml.jackson.databind.*" %>
<%@ page import="com.fasterxml.jackson.databind.node.*" %>

<%
    String jsonPath = application.getRealPath("/data/assignations.json");
    ObjectMapper mapper = new ObjectMapper();
    JsonNode data = mapper.readTree(new File(jsonPath));
    JsonNode stats = data.get("statistiques");
    ArrayNode assignations = (ArrayNode) data.get("assignations");
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Résultat</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.0/font/bootstrap-icons.css" rel="stylesheet">
    <style>
        body { background-color: #f5f5f5; }
        .voiture-card { border-left: 4px solid #0d6efd; }
        .voiture-card.no-voiture { border-left-color: #dc3545; }
        .itineraire-step { display: inline-flex; align-items: center; }
        .itineraire-arrow { margin: 0 6px; color: #6c757d; }
        .json-badge { background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); }
    </style>
</head>
<body>
<%@ include file="/WEB-INF/includes/sidebar.jsp" %>
<div class="main-content">

<div class="container">
    <h2 class="text-center mb-4">
        Résultat des assignations
    </h2>

    <div class="alert alert-success text-center">
        <i class="bi bi-calendar-check"></i> <strong>Date :</strong> <%= stats.get("dateReservation").asText() %> |
        <i class="bi bi-list-ol"></i> <strong>Réservations :</strong> <%= stats.get("nombreReservations").asInt() %> |
        <i class="bi bi-car-front"></i> <strong>Voitures utilisées :</strong> <%= stats.get("nombreVoitures").asInt() %> |
        <i class="bi bi-hourglass-split"></i> <strong>Temps d'attente :</strong> <%= stats.get("tempsAttente").asInt() %> min
    </div>

<%
    for (int idx = 0; idx < assignations.size(); idx++) {
        JsonNode assignation = assignations.get(idx);
        boolean hasVoiture = assignation.has("voiture") && !assignation.get("voiture").isNull();
        JsonNode voiture = hasVoiture ? assignation.get("voiture") : null;
        ArrayNode reservations = (ArrayNode) assignation.get("reservations");
        ArrayNode itineraire = (ArrayNode) assignation.get("itineraire");
%>
    <!-- Carte Voiture #<%= idx + 1 %> -->
    <div class="card mb-4 shadow-sm voiture-card<%= !hasVoiture ? " no-voiture" : "" %>">
        <div class="card-header <%= hasVoiture ? "bg-primary" : "bg-danger" %> text-white d-flex justify-content-between align-items-center">
            <div>
                <i class="bi bi-car-front-fill"></i>
                <% if (hasVoiture) { %>
                    <span class="badge bg-light text-dark ms-2"><%= voiture.get("matricule").asText() %></span>
                    &mdash; <%= voiture.get("marque").asText() %> <%= voiture.get("modele").asText() %>
                <% } else { %>
                     <em>Aucune voiture disponible</em> &mdash;
                <% } %>
                <% if (assignation.has("lieuAtterissage") && !assignation.get("lieuAtterissage").isNull()) { %>
                    <span class="badge bg-warning text-dark ms-2">
                        <i class="bi bi-airplane-fill"></i> <%= assignation.get("lieuAtterissage").asText() %>
                    </span>
                <% } %>
            </div>
            <div>
                <% if (hasVoiture) { %>
                    <span class="badge bg-light text-dark">
                        <i class="bi bi-people-fill"></i> <%= assignation.get("totalPassagers").asInt() %>/<%= voiture.get("nombrePlaces").asInt() %> places
                    </span>
                    <% String carburant = voiture.get("typeCarburant").asText();
                       if ("D".equals(carburant)) { %>
                        <span class="badge bg-success ms-1"><i class="bi bi-droplet-fill"></i> Diesel</span>
                    <% } else if ("E".equals(carburant)) { %>
                        <span class="badge bg-info ms-1"><i class="bi bi-fuel-pump"></i> Essence</span>
                    <% } else if ("G".equals(carburant)) { %>
                        <span class="badge bg-warning text-dark ms-1"><i class="bi bi-droplet-half"></i> Gasoil</span>
                    <% } else { %>
                        <span class="badge bg-secondary ms-1"><%= carburant %></span>
                    <% } %>
                    <span class="badge bg-secondary ms-1">Écart: +<%= assignation.get("ecartPlaces").asInt() %></span>
                <% } else { %>
                    <span class="badge bg-light text-danger"><i class="bi bi-x-circle"></i> Non assigné</span>
                <% } %>
            </div>
        </div>
        <div class="card-body">
            <h6 class="mb-3">
                <i class="bi bi-bookmark-fill text-primary"></i>
                Réservations (<%= reservations.size() %>)
                <% if (assignation.get("isGrouped").asBoolean()) { %>
                    <span class="badge bg-info ms-1"><i class="bi bi-people-fill"></i> Regroupées</span>
                <% } %>
            </h6>
            <div class="table-responsive">
                <table class="table table-sm table-bordered table-hover mb-3">
                    <thead class="table-light">
                        <tr>
                            <th><i class="bi bi-person"></i> Client</th>
                            <th><i class="bi bi-people"></i> Passagers</th>
                            <th><i class="bi bi-geo-alt"></i> Lieu</th>
                            <th><i class="bi bi-clock"></i> Heure</th>
                        </tr>
                    </thead>
                    <tbody>
                    <% for (int r = 0; r < reservations.size(); r++) {
                        JsonNode res = reservations.get(r);
                        int nombrePassager = res.get("nombrePassager").asInt();
                        int passagersAssignes = res.get("passagersAssignes").asInt();
                        boolean isPartiel = passagersAssignes < nombrePassager;
                    %>
                        <tr>
                            <td>Client #<%= res.get("idClient").asInt() %></td>
                            <td>
                                <% if (isPartiel) { %>
                                    <strong><%= passagersAssignes %></strong>/<%= nombrePassager %>
                                    <span class="badge bg-warning text-dark ms-1" title="Assignation partielle">
                                        <i class="bi bi-scissors"></i>
                                    </span>
                                <% } else { %>
                                    <strong><%= passagersAssignes %></strong>
                                <% } %>
                            </td>
                            <td><%= res.get("lieu").asText() %></td>
                            <td><%= res.get("heure").asText() %></td>
                        </tr>
                    <% } %>
                    </tbody>
                </table>
            </div>

            <% if (hasVoiture) { %>
            <div class="row">
                <div class="col-12 mb-3">
                    <h6><i class="bi bi-signpost-split-fill text-success"></i> Itinéraire aller-retour
                        <small class="text-muted fw-normal">(Aéroport &rarr; dépôt passagers &rarr; Aéroport)</small>
                    </h6>
                    <% if (itineraire.size() > 0) { %>
                        <div class="p-2 bg-light rounded mb-2 d-flex flex-wrap align-items-center gap-1">
                        <% for (int i = 0; i < itineraire.size(); i++) {
                            JsonNode step = itineraire.get(i);
                            boolean isAeroport = step.get("isAeroport").asBoolean();
                            boolean isLast = (i == itineraire.size() - 1);
                            double distVersProchain = step.get("distanceVersProchain").asDouble();
                        %>
                            <span class="itineraire-step">
                                <% if (isAeroport) { %>
                                    <span class="badge bg-danger px-2 py-1"><i class="bi bi-airplane"></i> <%= step.get("lieu").asText() %></span>
                                <% } else { %>
                                    <span class="badge bg-primary px-2 py-1"><i class="bi bi-building"></i> <%= step.get("lieu").asText() %></span>
                                <% } %>
                            </span>
                            <% if (!isLast) { %>
                                <span class="itineraire-arrow d-inline-flex align-items-center">
                                    <% if (distVersProchain > 0) { %>
                                        <span class="small text-muted mx-1"><%= distVersProchain %> km</span>
                                    <% } %>
                                    <i class="bi bi-arrow-right"></i>
                                </span>
                            <% } %>
                        <% } %>
                        </div>
                    <% } else { %>
                        <span class="text-muted">Itinéraire non disponible</span>
                    <% } %>
                </div>
                <div class="col-12">
                    <div class="row g-2">
                        <div class="col-6 col-md-3">
                            <div class="card text-center p-2 border-primary h-100">
                                <div class="small text-muted"><i class="bi bi-rulers"></i> Distance totale</div>
                                <div class="fw-bold text-primary fs-5">
                                    <% if (assignation.get("distanceTotaleKm").asDouble() > 0) { %>
                                        <%= assignation.get("distanceTotaleKm").asDouble() %> km
                                    <% } else { %><span class="text-muted fs-6">N/A</span><% } %>
                                </div>
                                <div class="small text-muted">aller-retour</div>
                            </div>
                        </div>
                        <div class="col-6 col-md-3">
                            <div class="card text-center p-2 border-info h-100">
                                <div class="small text-muted"><i class="bi bi-speedometer2"></i> Vitesse moy.</div>
                                <div class="fw-bold text-info fs-5">
                                    <% if (assignation.get("vitesseKmH").asInt() > 0) { %>
                                        <%= assignation.get("vitesseKmH").asInt() %> km/h
                                    <% } else { %><span class="text-muted fs-6">N/A</span><% } %>
                                </div>
                            </div>
                        </div>
                        <div class="col-6 col-md-3">
                            <div class="card text-center p-2 border-secondary h-100">
                                <div class="small text-muted"><i class="bi bi-hourglass-split"></i> Durée trajet</div>
                                <div class="fw-bold fs-5">
                                    <% int minutes = assignation.get("tempsTrajetMinutes").asInt();
                                       if (minutes > 0) {
                                        int hh = minutes / 60;
                                        int mm = minutes % 60;
                                    %>
                                        <%= hh > 0 ? hh + "h " : "" %><%= mm %>min
                                    <% } else { %><span class="text-muted fs-6">N/A</span><% } %>
                                </div>
                                <div class="small text-muted">durée de conduite</div>
                            </div>
                        </div>
                        <div class="col-6 col-md-3">
                            <div class="card text-center p-2 border-warning h-100">
                                <div class="small text-muted"><i class="bi bi-clock-history"></i> Retour aéroport</div>
                                <div class="fw-bold text-warning-emphasis fs-5">
                                    <% if (assignation.has("heureRetourAeroport") && !assignation.get("heureRetourAeroport").isNull()) { %>
                                        <%= assignation.get("heureRetourAeroport").asText() %>
                                    <% } else { %><span class="text-muted fs-6">N/A</span><% } %>
                                </div>
                                <div class="small text-muted">heure estimée</div>
                            </div>
                        </div>
                        <div class="col-6 col-md-3">
                            <div class="card text-center p-2 border-success h-100">
                                <div class="small text-muted"><i class="bi bi-calendar-event"></i> Départ assignation</div>
                                <div class="fw-bold text-success fs-5"><%= assignation.get("departAssignation").asText() %></div>
                                <div class="small text-muted">date et heure de départ</div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <% } %>
        </div>
    </div>
<% } %>

    <div class="text-center mt-4">
        <a href="saisie" class="btn btn-primary">
            <i class="bi bi-arrow-left"></i> Retour à l'assignation
        </a>
    </div>
</div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
