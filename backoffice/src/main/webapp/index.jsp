<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Backoffice — Accueil</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.0/font/bootstrap-icons.css" rel="stylesheet">
</head>
<body>
<%@ include file="/WEB-INF/includes/sidebar.jsp" %>
<div class="main-content">
    <h1>Bienvenue dans le Backoffice de Gestion de Voitures</h1>
    <p>Utilisez les liens ci-dessous pour naviguer :</p>
    <ul>
        <li><a href="<%= request.getContextPath() %>/voiture/liste">Voir la Liste des voitures</a></li>
        <li><a href="<%= request.getContextPath() %>/reservation/saisie">Créer une Réservation</a></li>
        <li><a href="<%= request.getContextPath() %>/assignation/saisie">Voir les Assignations</a></li>
    </ul>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>