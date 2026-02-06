<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Login</title>
</head>
<body>
<h1>Login</h1>
<!-- Use contextPath so this works no matter the war/context name -->
<form action="loginpost" method="post">
    <label for="userId">User ID:</label>
    <input type="text" id="userId" name="userId" />
    <button type="submit">Login</button>
</form>
</body>
</html>

