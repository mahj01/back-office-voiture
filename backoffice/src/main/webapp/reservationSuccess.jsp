<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Réservation Créée</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 600px;
            margin: 50px auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .success-container {
            background-color: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            text-align: center;
        }
        .success-icon {
            font-size: 60px;
            color: #28a745;
            margin-bottom: 20px;
        }
        h2 {
            color: #28a745;
        }
        .details {
            text-align: left;
            margin-top: 20px;
            padding: 20px;
            background-color: #f8f9fa;
            border-radius: 4px;
        }
        .details p {
            margin: 10px 0;
            color: #555;
        }
        .details strong {
            color: #333;
        }
        .btn-back {
            display: inline-block;
            margin-top: 20px;
            padding: 12px 30px;
            background-color: #007bff;
            color: white;
            text-decoration: none;
            border-radius: 4px;
        }
        .btn-back:hover {
            background-color: #0056b3;
        }
    </style>
</head>
<body>

<div class="success-container">
    <div class="success-icon">✓</div>
    <h2>${message}</h2>
    
    <div class="details">
        <p><strong>ID Client:</strong> ${reservation.idClient}</p>
        <p><strong>Date d'arrivée:</strong> ${reservation.dateArriver}</p>
        <p><strong>Nombre de passagers:</strong> ${reservation.nombrePassager}</p>
    </div>
    
    <a href="createReservation.jsp" class="btn-back">Nouvelle Réservation</a>
</div>

</body>
</html>
