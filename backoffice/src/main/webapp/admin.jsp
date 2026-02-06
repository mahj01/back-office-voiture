<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html>
<head>
    <title>Admin Area</title>
</head>
<body>
<h2>Admin Page</h2>
<p>Welcome, ${user != null ? user.username : 'unknown'}</p>
<p>Role: ${user != null ? user.role : 'none'}</p>
</body>
</html>

