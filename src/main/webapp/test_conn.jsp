<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ include file="includes/header.jsp" %>
<!DOCTYPE html>
<html>
<head><title>Connection Test</title></head>
<body>
    <h2>Connection Test</h2>
    
    <h3>Student Page Connection Test:</h3>
    <%
    Connection conn = null;
    try {
        Class.forName("oracle.jdbc.OracleDriver");
        String url = "jdbc:oracle:thin:@localhost:1521:xe";
        conn = DriverManager.getConnection(url, "c##library", "1234");
        
        PreparedStatement pstmt = conn.prepareStatement("SELECT COUNT(*) as total FROM c##library.books");
        ResultSet rs = pstmt.executeQuery();
        if (rs.next()) {
            out.println("<p>Student page sees: " + rs.getInt("total") + " books</p>");
        }
        rs.close();
        pstmt.close();
        
        // Test with different query
        pstmt = conn.prepareStatement("SELECT book_id, title, category FROM c##library.books ORDER BY book_id ASC FETCH FIRST 5 ROWS ONLY");
        rs = pstmt.executeQuery();
        out.println("<h4>First 5 books:</h4><ul>");
        while(rs.next()) {
            out.println("<li>" + rs.getInt("book_id") + ": " + rs.getString("title") + " (" + rs.getString("category") + ")</li>");
        }
        out.println("</ul>");
        rs.close();
        pstmt.close();
        
    } catch (Exception e) {
        out.println("Error: " + e.getMessage());
        e.printStackTrace(new java.io.PrintWriter(out));
    } finally {
        if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
    }
    %>
    
    <h3>Check Current Schema:</h3>
    <%
    try {
        Class.forName("oracle.jdbc.OracleDriver");
        String url = "jdbc:oracle:thin:@localhost:1521:xe";
        conn = DriverManager.getConnection(url, "c##library", "1234");
        
        PreparedStatement pstmt = conn.prepareStatement("SELECT SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') as current_schema FROM DUAL");
        ResultSet rs = pstmt.executeQuery();
        if (rs.next()) {
            out.println("<p>Current schema: " + rs.getString("current_schema") + "</p>");
        }
        rs.close();
        pstmt.close();
        
    } catch (Exception e) {
        out.println("Schema error: " + e.getMessage());
    } finally {
        if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
    }
    %>
    
    <a href="student/browse_books.jsp">← Test Student Page</a> | 
    <a href="librarian/manage_books.jsp">Test Librarian Page</a>
</body>
</html>