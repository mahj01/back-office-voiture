<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Profile</title>
</head>
<body>
<h1>Profile</h1>
<p>
    <% Object uid = request.getAttribute("userSession"); %>
    <% if (uid != null) { %>
        User ID: <%= uid %>
    <% } else { %>
        No user is logged in.
    <% } %>
</p>
<a href="login">Back to login</a>
</body>
</html>

