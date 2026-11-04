<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%
    String username = request.getParameter("username");
    String password = request.getParameter("password");

    // Debug logging
    System.out.println("=== LOGIN DEBUG ===");
    System.out.println("Username received: '" + username + "'");
    System.out.println("Password received: '" + password + "'");

    if (username == null || password == null || username.trim().isEmpty()) {
        System.out.println("Redirecting - null/empty params");
        response.sendRedirect("login.jsp?error=1");
        return;
    }

    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    try {
        Class.forName("oracle.jdbc.OracleDriver");
        
        // 🔥 EXACT CONNECTION STRING THAT WORKED IN TEST
        String url = "jdbc:oracle:thin:@localhost:1521:xe";
        conn = DriverManager.getConnection(url, "c##library", "1234");
        System.out.println("✅ Connected to database");

        // 🔥 EXACT QUERY WITH SCHEMA PREFIX
        String sql = "SELECT user_id, username, role FROM c##library.users WHERE username = ? AND password_hash = ?";
        pstmt = conn.prepareStatement(sql);
        pstmt.setString(1, username.trim());
        pstmt.setString(2, password);
        
        System.out.println("Executing query: " + sql);
        System.out.println("Params: " + username.trim() + ", " + password);
        
        rs = pstmt.executeQuery();

        if (rs.next()) {
            System.out.println("✅ USER FOUND - Setting session attributes");
            
            session.setAttribute("userId", rs.getInt("user_id"));
            session.setAttribute("username", rs.getString("username"));
            session.setAttribute("role", rs.getString("role"));

            String role = rs.getString("role");
            System.out.println("User role: " + role);
            
            if ("admin".equals(role)) {
                System.out.println("Redirecting to admin dashboard");
                response.sendRedirect("../admin/dashboard.jsp");
            } else if ("librarian".equals(role)) {
                System.out.println("Redirecting to librarian dashboard");
                response.sendRedirect("../librarian/dashboard.jsp");
            } else if ("student".equals(role)) {
                System.out.println("Redirecting to student dashboard");
                response.sendRedirect("../student/dashboard.jsp");
            } else {
                System.out.println("Unknown role, redirecting to login");
                response.sendRedirect("login.jsp?error=1");
            }
        } else {
            System.out.println("❌ USER NOT FOUND in database");
            response.sendRedirect("login.jsp?error=1");
        }
    } catch (Exception e) {
        System.err.println("❌ EXCEPTION in login: " + e.getMessage());
        e.printStackTrace();
        response.sendRedirect("login.jsp?error=1");
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException ignored) {}
        if (pstmt != null) try { pstmt.close(); } catch (SQLException ignored) {}
        if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
    }
%>