<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Login - OpenLibrary</title>
    <link rel="stylesheet" href="../css/style.css">
</head>
<body class="auth-body">
    <div class="auth-container">
        <h2>📘 OpenLibrary</h2>
        <p>Library Management System</p>
        
        <% if (request.getParameter("error") != null) { %>
            <div class="alert alert-error">Invalid username or password.</div>
        <% } %>

        <form method="POST" action="login_process.jsp">
            <div class="form-group">
                <label style="padding: 5px 0px;">Username</label>
                <input type="text" name="username" required placeholder="e.g., admin">
            </div>
            <div class="form-group">
                <label>Password</label>
                <input type="password" name="password" required placeholder="e.g., admin123">
            </div>
            <button type="submit" class="btn btn-primary">Sign In</button>
        </form>
        <p class="hint">Test: <code>admin</code> / <code>admin123</code></p>
    </div>
</body>
</html>