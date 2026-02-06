<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="org.itu.entity.Hotel" %>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Créer une Réservation</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 600px;
            margin: 50px auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        h2 {
            color: #333;
            text-align: center;
        }
        form {
            background-color: white;
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

<h2>Créer une Réservation</h2>

<form action="create" method="post">

    <label>ID Client :</label>
    <input type="number" name="idClient" required min="1">

    <label>Date et heure d'arrivée :</label>
    <input type="datetime-local" name="dateArriver" required>

    <label>Nombre de passagers :</label>
    <input type="number" name="nombrePassager" required min="1">

    <label>Hôtel :</label>
    <select name="idHotel" required>
        <option value="">-- Sélectionner un hôtel --</option>

        <%
            List<Hotel> hotels = (List<Hotel>) request.getAttribute("hotels");
            if (hotels != null) {
                for (Hotel hotel : hotels) {
        %>
            <option value="<%= hotel.getId() %>">
                <%= hotel.getNom() %>
            </option>
        <%
                }
            }
        %>
    </select>

    <button type="submit">Créer la Réservation</button>
</form>

</body>
</html>
