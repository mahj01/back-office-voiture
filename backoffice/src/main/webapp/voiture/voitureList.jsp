<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<html>
<head>
    <title>Liste des voitures</title>
    <style>table{border-collapse:collapse;width:100%}th,td{border:1px solid #ddd;padding:8px}</style>

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
<h2>Liste des voitures</h2>
<p><a href="createVoiture.jsp">Créer une nouvelle voiture</a></p>
<table>
    <thead>
    <tr>
        <th>ID</th>
        <th>Matricule</th>
        <th>Marque</th>
        <th>Modèle</th>
        <th>Nombre de places</th>
        <th>Type carburant</th>
        <th>Actions</th>
    </tr>
    </thead>
    <tbody>
    <%
        java.util.List voitures = (java.util.List) request.getAttribute("voitures");
        if (voitures != null) {
            for (Object o : voitures) {
                org.itu.entity.Voiture v = (org.itu.entity.Voiture) o;
    %>
    <tr>
        <td><%= v.getId() %></td>
        <td><%= v.getMatricule() %></td>
        <td><%= v.getMarque() %></td>
        <td><%= v.getModele() %></td>
        <td><%= v.getNombrePlaces() %></td>
        <td><%= v.getTypeCarburant() %></td>
        <td>
            <a href="viewVoiture.jsp?id=<%= v.getId() %>">Voir</a> |
            <a href="editVoiture.jsp?id=<%= v.getId() %>">Modifier</a> |
            <a href="deleteVoiture.jsp?id=<%= v.getId() %>">Supprimer</a>
        </td>
    </tr>
    <%      }
        } else { %>
    <tr><td colspan="7">Aucune voiture trouvée.</td></tr>
    <% } %>
    </tbody>
</table>
</body>
</html>
