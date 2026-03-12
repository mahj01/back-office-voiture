<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Réservation Créée</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.0/font/bootstrap-icons.css" rel="stylesheet">
    <style>
        .success-container {
            background-color: white;
            max-width: 600px;
            margin: 20px auto;
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
<%@ include file="/WEB-INF/includes/sidebar.jsp" %>
<div class="main-content">

<div class="success-container">
    <div class="success-icon">✓</div>
    <h2><% out.print(request.getAttribute("message")); %></h2>
    
    <div class="details">
        <p><strong>ID Client:</strong> <% out.print(((org.itu.entity.Reservation)request.getAttribute("reservation")).getIdClient()); %></p>
        <p><strong>Date d'arrivée:</strong> <% out.print(((org.itu.entity.Reservation)request.getAttribute("reservation")).getDateArriver()); %></p>
        <p><strong>Nombre de passagers:</strong> <% out.print(((org.itu.entity.Reservation)request.getAttribute("reservation")).getNombrePassager()); %></p>
    </div>
    
    <a href="saisie" class="btn-back">Nouvelle Réservation</a>
</div>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
