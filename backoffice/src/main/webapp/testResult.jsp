<%@ page import="java.util.List" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    String name = (String) request.getAttribute("name");
    String subscribe = (String) request.getAttribute("subscribe");
    Object languageObj = request.getAttribute("language");
    String languages = "";
    if (languageObj instanceof List) {
        languages = String.join(", ", ((List<?>) languageObj).stream()
                .map(Object::toString)
                .toArray(String[]::new));
    } else if (languageObj instanceof String) {
        languages = (String) languageObj;
    }
%>
<html>
<head>
    <title>Test Result</title>
</head>
<body>

<h2>Form Submission Result</h2>

<p>
    Thank you, <strong><%= name %></strong>.
    <br><br>

    Subscription status: <strong><%= subscribe %></strong>
    <br><br>

    Preferred language(s): <strong><%= languages %></strong>
    <br><br>

    Your information has been successfully processed.
</p>

</body>
</html>
