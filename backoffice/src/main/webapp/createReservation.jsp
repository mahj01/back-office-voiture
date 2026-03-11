<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="org.itu.entity.Lieu" %>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Créer une Réservation</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.0/font/bootstrap-icons.css" rel="stylesheet">
    <style>
        h2 {
            color: #333;
            text-align: center;
        }
        form {
            background-color: white;
            max-width: 600px;
            margin: 20px auto;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        label {
            display: block;
            margin-bottom: 5px;
            font-weight: bold;
            color: #555;
        }
        input, select {
            width: 100%;
            padding: 10px;
            margin-bottom: 20px;
            border: 1px solid #ddd;
            border-radius: 4px;
        }
        button {
            width: 100%;
            padding: 12px;
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
    </style>
</head>
<body>
<%@ include file="/WEB-INF/includes/sidebar.jsp" %>
<div class="main-content">

<h2>Créer une Réservation</h2>

<form action="create" method="post">

    <label>ID Client :</label>
    <input type="number" name="idClient" required min="1">

    <label>Date et heure d'arrivée :</label>
    <input type="datetime-local" name="dateArriver" required>

    <label>Nombre de passagers :</label>
    <input type="number" name="nombrePassager" required min="1">

    <label>Lieu :</label>
    <select name="idLieu" required>
        <option value="">-- Sélectionner un lieu --</option>

        <%
            List<Lieu> lieux = (List<Lieu>) request.getAttribute("lieux");
            if (lieux != null) {
                for (Lieu lieu : lieux) {
        %>
            <option value="<%= lieu.getId() %>">
                <%= lieu.getLibelle() %> (<%= lieu.getTypeLieu() %>)
            </option>
        <%
                }
            }
        %>
    </select>

    <label>Aéroport d'atterrissage :</label>
    <select name="idLieuAtterissage" required>
        <option value="">-- Sélectionner un aéroport --</option>
        <%
            List<Lieu> aeroports = (List<Lieu>) request.getAttribute("aeroports");
            if (aeroports != null) {
                for (Lieu aero : aeroports) {
        %>
            <option value="<%= aero.getId() %>"><%= aero.getLibelle() %></option>
        <%
                }
            }
        %>
    </select>

    <button type="submit">Créer la Réservation</button>
</form>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
