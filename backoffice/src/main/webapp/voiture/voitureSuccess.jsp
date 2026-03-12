<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<html>
<head>
    <title>Voiture — Succès</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.0/font/bootstrap-icons.css" rel="stylesheet">
    <style>
        .card{background:#f7f7f7;padding:16px;border-radius:6px;border:1px solid #e1e1e1}
        .field{margin:8px 0}
        a.button{display:inline-block;margin-top:12px;padding:8px 12px;background:#007bff;color:#fff;text-decoration:none;border-radius:4px}
    </style>
</head>
<body>
<%@ include file="/WEB-INF/includes/sidebar.jsp" %>
<div class="main-content">
    <h2>Opération terminée</h2>
    <div class="card">
        <p><strong>Message :</strong>
        <%= (request.getAttribute("message")!=null? request.getAttribute("message") : "Opération réussie") %></p>

        <%
            org.itu.entity.Voiture voiture = (org.itu.entity.Voiture) request.getAttribute("voiture");
            if (voiture != null) {
        %>
        <div class="field"><strong>ID :</strong> <%= voiture.getId() %></div>
        <div class="field"><strong>Matricule :</strong> <%= voiture.getMatricule() %></div>
        <div class="field"><strong>Marque :</strong> <%= voiture.getMarque() %></div>
        <div class="field"><strong>Modèle :</strong> <%= voiture.getModele() %></div>
        <div class="field"><strong>Nombre de places :</strong> <%= voiture.getNombrePlaces() %></div>
        <div class="field"><strong>Type carburant :</strong> <%= voiture.getTypeCarburant() %></div>
        <%
            } else {
        %>
        <p>Aucune donnée de voiture fournie.</p>
        <%
            }
        %>

        <p>
            <a class="button" href="../liste">Retour à la liste des voitures</a>
        </p>
    </div>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
