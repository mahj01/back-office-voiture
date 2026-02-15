<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<html>
<head>
    <title>Afficher voiture</title>
<style>
/* styles existants */
form {
    max-width: 700px;
    margin: 20px auto;
    padding: 16px;
    background: #f9f9f9;
    border-radius: 6px;
    box-shadow: 0 1px 3px rgba(0,0,0,0.06);
    box-sizing: border-box;
}

label {
    display: block;
    margin: 8px 0 6px;
    font-weight: 600;
    color: #333;
}

input[type="number"],
input[type="datetime-local"],
select,
textarea {
    width: 100%;
    padding: 10px;
    margin-bottom: 12px;
    border: 1px solid #ccc;
    border-radius: 4px;
    font-size: 14px;
    box-sizing: border-box;
    background: #fff;
}

input:focus,
select:focus,
textarea:focus {
    outline: none;
    border-color: #007bff;
    box-shadow: 0 0 0 4px rgba(0,123,255,0.08);
}

.form-row {
    display: flex;
    gap: 12px;
    align-items: center;
}

.form-row > * {
    flex: 1;
}

button {
    margin-top: 6px;
    padding: 12px;
    width: 100%;
    background-color: #007bff;
    color: white;
    border: none;
    border-radius: 4px;
    font-size: 16px;
    cursor: pointer;
}
button:hover {
    background-color: #0056b3;
}

@media (max-width: 560px) {
    .form-row {
        flex-direction: column;
    }
}
</style>
</head>
<body>
<h2>Détails de la voiture</h2>
<%
    org.itu.entity.Voiture v = (org.itu.entity.Voiture) request.getAttribute("voiture");
    String id = request.getParameter("id");
%>
<% if (v != null) { %>
    <p><strong>ID:</strong> <%= v.getId() %></p>
    <p><strong>Matricule:</strong> <%= v.getMatricule() %></p>
    <p><strong>Marque:</strong> <%= v.getMarque() %></p>
    <p><strong>Modèle:</strong> <%= v.getModele() %></p>
    <p><strong>Nombre de places:</strong> <%= v.getNombrePlaces() %></p>
    <p><strong>Type carburant:</strong> <%= v.getTypeCarburant() %></p>
<% } else { %>
    <p>Aucune donnée disponible pour la voiture (id=<%= id %>).</p>
<% } %>
<p><a href="voitureList.jsp">Retour à la liste</a></p>
</body>
</html>
