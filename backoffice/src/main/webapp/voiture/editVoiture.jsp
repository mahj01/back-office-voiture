<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<html>
<head>
    <title>Modifier une voiture</title>

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
<h2>Modifier une voiture</h2>
<%
    org.itu.entity.Voiture v = (org.itu.entity.Voiture) request.getAttribute("voiture");
    String sid = request.getParameter("id");
    if (v == null && sid != null) {
        v = new org.itu.entity.Voiture(0, request.getParameter("matricule"), request.getParameter("marque"), request.getParameter("modele"), request.getParameter("nombrePlaces")!=null?Integer.parseInt(request.getParameter("nombrePlaces")):0, request.getParameter("typeCarburant"));
        try { v.setId(Integer.parseInt(sid)); } catch(Exception e) {}
    }
%>
<form method="post" action="/update">
    <input type="hidden" name="id" value="<%= (v!=null?v.getId(): (request.getParameter("id")!=null?request.getParameter("id"):"")) %>">
    <label>Matricule: <input type="text" name="matricule" value="<%= (v!=null?v.getMatricule():request.getParameter("matricule")) %>" required></label><br>
    <label>Marque: <input type="text" name="marque" value="<%= (v!=null?v.getMarque():request.getParameter("marque")) %>" required></label><br>
    <label>Modèle: <input type="text" name="modele" value="<%= (v!=null?v.getModele():request.getParameter("modele")) %>" required></label><br>
    <label>Nombre de places: <input type="number" name="nombrePlaces" min="1" value="<%= (v!=null?v.getNombrePlaces(): (request.getParameter("nombrePlaces")!=null?Integer.parseInt(request.getParameter("nombrePlaces")):1)) %>" required></label><br>
    <label>Type carburant: <input type="text" name="typeCarburant" value="<%= (v!=null?v.getTypeCarburant():request.getParameter("typeCarburant")) %>" required></label><br>
    <button type="submit">Mettre à jour</button>
</form>
<p><a href="voitureList.jsp">Retour à la liste</a></p>
</body>
</html>
