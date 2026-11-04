<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<!DOCTYPE html>
<html>
<head>
    <title>DB Test - OpenLibrary</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .success { color: green; }
        .error { color: red; }
        table { border-collapse: collapse; width: 100%; margin-top: 10px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h2>🔗 Oracle Database Connection Test</h2>
    
    <%
    Connection conn = null;
    try {
        // Load Oracle driver
        Class.forName("oracle.jdbc.OracleDriver");
        out.println("<p class='success'>✅ Oracle Driver loaded successfully</p>");
        
        // Connect to Oracle with your credentials
        String url = "jdbc:oracle:thin:@localhost:1521:xe";
        conn = DriverManager.getConnection(url, "c##library", "1234");
        out.println("<p class='success'>✅ Connected to Oracle as c##library</p>");
        
        // Test query
        Statement stmt = conn.createStatement();
        ResultSet rs = stmt.executeQuery("SELECT user_id, username, password_hash, role FROM users WHERE ROWNUM <= 5");
        
        out.println("<h3>📋 Users in Database:</h3>");
        out.println("<table><tr><th>ID</th><th>Username</th><th>Password</th><th>Role</th></tr>");
        while(rs.next()) {
            out.println("<tr>");
            out.println("<td>" + rs.getInt("user_id") + "</td>");
            out.println("<td>" + rs.getString("username") + "</td>");
            out.println("<td>" + rs.getString("password_hash") + "</td>");
            out.println("<td>" + rs.getString("role") + "</td>");
            out.println("</tr>");
        }
        out.println("</table>");
        rs.close();
        stmt.close();
        
    } catch (Exception e) {
        out.println("<p class='error'>❌ Connection failed: " + e.getMessage() + "</p>");
        e.printStackTrace(new java.io.PrintWriter(out));
    } finally {
        if (conn != null) {
            try { 
                conn.close(); 
                out.println("<p>🔒 Database connection closed</p>");
            } catch (SQLException ignored) {}
        }
    }
    %>
    
    <hr>
    <p><a href="auth/login.jsp">← Back to Login</a></p>
</body>
</html>