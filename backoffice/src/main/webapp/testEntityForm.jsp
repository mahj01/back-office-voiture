<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<html>
<head>
    <title>Employe Form</title>
</head>
<body>

<h2>Create Employee</h2>

<form action="testEntityJson" method="post">

    <label for="nom">Employee Name:</label><br>
    <input type="text" id="nom" name="nom" required>
    <br><br>

    <label for="departement">Department:</label><br>
    <input type="text" id="departement" name="departement" required>
    <br><br>

    <button type="submit">Submit</button>
</form>

</body>
</html>
