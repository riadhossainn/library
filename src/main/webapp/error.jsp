<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="includes/header.jsp" %>
<%@ page isErrorPage="true" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Error - OpenLibrary</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
    <div class="container">
        <div class="card" style="text-align: center; padding: 3rem;">
            <h2>⚠️ Something went wrong</h2>
            <p style="color: var(--danger); margin: 1rem 0;">
                An error occurred while processing your request.
            </p>
            
            <% if (exception != null) { %>
                <details style="margin: 1rem 0; text-align: left;">
                    <summary>Error Details</summary>
                    <pre style="background: var(--bg); padding: 1rem; border-radius: 4px; overflow-x: auto;">
<%= exception.getMessage() %>
                    </pre>
                </details>
            <% } %>
            
            <div style="margin: 2rem 0;">
                <a href="javascript:history.back()" class="btn btn-primary" style="margin-right: 1rem;">Go Back</a>
                <a href="admin/dashboard.jsp" class="btn btn-secondary">Home Dashboard</a>
            </div>
            
            <p style="margin-top: 2rem; color: var(--text-light);">
                If this error persists, please contact your system administrator.
            </p>
        </div>
    </div>
</body>
</html>