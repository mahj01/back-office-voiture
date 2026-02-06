<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<html>
<head>
    <title>Test Data Form</title>
</head>
<body>

<h2>Submit Test Data</h2>

<form action="testData4" method="post">

    <label>Name:</label><br>
    <input type="text" name="name"><br><br>

    <label>Subscribe?</label>
    <input type="checkbox" name="subscribe" value="yes"><br><br>

    <label>Select Language(s):</label><br>
    <input type="checkbox" name="language" value="english"> English<br>
    <input type="checkbox" name="language" value="french"> French<br>
    <input type="checkbox" name="language" value="spanish"> Spanish<br><br>

    <input type="submit" value="Submit">
</form>

</body>
</html>
