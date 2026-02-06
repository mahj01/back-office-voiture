<!-- jsp -->
<%@ page contentType="text/html; charset=UTF-8" %>
<%@ page import="java.util.List" %>
<!DOCTYPE html>
<html>
<head>
    <title>Upload result</title>
</head>
<body>
<h1>Upload result</h1>
<%
    Object o = request.getAttribute("savedFiles");
    List<String> saved = (o instanceof List) ? (List<String>) o : null;
    if (saved == null || saved.isEmpty()) {
%>
<p>No files saved.</p>
<%
} else {
%>
<ul>
    <%
        for (String p : saved) {
    %>
    <li><%= p %></li>
    <%
        }
    %>
</ul>
<%
    }
%>
</body>
</html>
