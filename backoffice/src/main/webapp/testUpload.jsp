<!-- jsp -->
<%@ page contentType="text/html; charset=UTF-8" %>
<!DOCTYPE html>
<html>
<head>
    <title>Upload files</title>
</head>
<body>
<h1>Upload files</h1>
<form action="upload" method="post" enctype="multipart/form-data">
    <label>Select files (multiple allowed):</label><br/>
    <input type="file" name="files" multiple/><br/><br/>
    <button type="submit">Upload</button>
</form>
</body>
</html>
