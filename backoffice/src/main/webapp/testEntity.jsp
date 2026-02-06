<%@ page import="org.itu.Employe" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<%
    Employe emp = (Employe) request.getAttribute("employe");

    String nom = (emp != null) ? emp.getNom() : "";
    String departement = (emp != null) ? emp.getDepartement() : "";
%>

<html>
<head>
    <title>Employe Details</title>
</head>
<body>

<h2>Employee Information</h2>

<p>
    Employee Name: <strong><%= nom %></strong>
    <br><br>

    Department: <strong><%= departement %></strong>
    <br><br>

    The employee data has been successfully received and processed.
</p>

</body>
</html>
