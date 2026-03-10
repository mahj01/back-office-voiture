<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Assignation des Voitures</title>
    <!-- Bootstrap CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Bootstrap Icons -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.0/font/bootstrap-icons.css" rel="stylesheet">
    <style>
        body {
            background-color: #f5f5f5;
            padding-top: 50px;
        }
    </style>
</head>
<body>

<div class="container" style="max-width: 600px;">
    <h2 class="text-center mb-4">
        <i class="bi bi-car-front-fill text-primary"></i> 
        Assignation des Voitures aux Réservations
    </h2>

    <div class="alert alert-info">
        <h5><i class="bi bi-info-circle"></i> Règles d'assignation :</h5>
        <ul class="mb-0">
            <li>La voiture doit avoir assez de places (>= nombre de passagers)</li>
            <li>On choisit la voiture avec le moins d'écart de places libres</li>
            <li>En cas d'égalité, on privilégie les véhicules diesel</li>
            <li>Si plusieurs diesel, sélection aléatoire</li>
        </ul>
    </div>

    <div class="card">
        <div class="card-body">
            <form action="resultat" method="post">
                <div class="mb-3">
                    <label for="dateReservation" class="form-label fw-bold">
                        <i class="bi bi-calendar3"></i> Date des réservations :
                    </label>
                    <input type="date" class="form-control" id="dateReservation" 
                           name="dateReservation" required value="2026-03-05">
                </div>

                <button type="submit" class="btn btn-success w-100">
                    <i class="bi bi-search"></i> Voir les assignations
                </button>
            </form>
        </div>
    </div>
</div>

<!-- Bootstrap JS -->
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
