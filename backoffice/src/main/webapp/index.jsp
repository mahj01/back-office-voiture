<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Test Servlet Integration</title>
</head>
<body>
    <h1>Bienvenue dans le Backoffice de Gestion de Voitures</h1>
    <p>Utilisez les liens ci-dessous pour naviguer :</p>
    <ul>
        <li><a href="<%= request.getContextPath() %>/voiture/liste">Voir la Liste des voitures</a></li>
        <li><a href="<%= request.getContextPath() %>/reservation/saisie">Créer une Réservation</a></li>
        <li><a href="<%= request.getContextPath() %>/assignation/saisie">Voir les Assignations</a></li>
    </ul>
</body>
</html>