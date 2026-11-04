<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    // Redirect to login if not logged in
    if (session.getAttribute("userId") == null) {
        response.sendRedirect("auth/login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head><title>Welcome</title></head>
<body>
<h1>Welcome, <%= session.getAttribute("username") %>!</h1>
<p>You are logged in as: <strong><%= session.getAttribute("role") %></strong></p>
<a href="logout.jsp">Logout</a>
</body>
</html>