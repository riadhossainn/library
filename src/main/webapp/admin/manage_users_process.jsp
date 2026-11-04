<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, java.util.UUID" %>
<%
    // Verify admin access
    if (!"admin".equals(session.getAttribute("role"))) {
        response.sendRedirect("../auth/login.jsp");
        return;
    }

    String action = request.getParameter("action");
    String message = "";
    String messageType = "";

    Connection conn = null;
    PreparedStatement pstmt = null;

    try {
        Class.forName("oracle.jdbc.OracleDriver");
        String url = "jdbc:oracle:thin:@localhost:1521:xe";
        conn = DriverManager.getConnection(url, "c##library", "1234");

        if ("create".equals(action)) {
            String username = request.getParameter("username");
            String name = request.getParameter("name");
            String email = request.getParameter("email");
            String role = request.getParameter("role");
            String password = request.getParameter("password");

            pstmt = conn.prepareStatement(
                "INSERT INTO c##library.users (username, password_hash, role, name, email) VALUES (?, ?, ?, ?, ?)"
            );
            pstmt.setString(1, username);
            pstmt.setString(2, password); // Plain text for simplicity
            pstmt.setString(3, role);
            pstmt.setString(4, name);
            pstmt.setString(5, email);
            
            int rowsAffected = pstmt.executeUpdate();
            if (rowsAffected > 0) {
                message = "User created successfully!";
                messageType = "success";
            } else {
                message = "Failed to create user.";
                messageType = "error";
            }
        }
        else if ("update".equals(action)) {
            String userId = request.getParameter("user_id");
            String username = request.getParameter("username");
            String name = request.getParameter("name");
            String email = request.getParameter("email");
            String role = request.getParameter("role");
            String password = request.getParameter("password");

            if (password != null && !password.trim().isEmpty()) {
                // Update with new password
                pstmt = conn.prepareStatement(
                    "UPDATE c##library.users SET username=?, password_hash=?, role=?, name=?, email=? WHERE user_id=?"
                );
                pstmt.setString(1, username);
                pstmt.setString(2, password); // Plain text
                pstmt.setString(3, role);
                pstmt.setString(4, name);
                pstmt.setString(5, email);
                pstmt.setString(6, userId);
            } else {
                // Update without changing password
                pstmt = conn.prepareStatement(
                    "UPDATE c##library.users SET username=?, role=?, name=?, email=? WHERE user_id=?"
                );
                pstmt.setString(1, username);
                pstmt.setString(2, role);
                pstmt.setString(3, name);
                pstmt.setString(4, email);
                pstmt.setString(5, userId);
            }
            
            int rowsAffected = pstmt.executeUpdate();
            if (rowsAffected > 0) {
                message = "User updated successfully!";
                messageType = "success";
            } else {
                message = "Failed to update user.";
                messageType = "error";
            }
        }
        else if ("delete".equals(action)) {
            String userId = request.getParameter("user_id");
            
            // Check if user exists
            pstmt = conn.prepareStatement("SELECT COUNT(*) as count FROM c##library.users WHERE user_id = ?");
            pstmt.setString(1, userId);
            ResultSet rs = pstmt.executeQuery();
            boolean exists = false;
            if (rs.next()) exists = rs.getInt("count") > 0;
            rs.close();
            
            if (exists) {
                pstmt = conn.prepareStatement("DELETE FROM c##library.users WHERE user_id = ?");
                pstmt.setString(1, userId);
                
                int rowsAffected = pstmt.executeUpdate();
                if (rowsAffected > 0) {
                    message = "User deleted successfully!";
                    messageType = "success";
                } else {
                    message = "Failed to delete user.";
                    messageType = "error";
                }
            } else {
                message = "User not found.";
                messageType = "error";
            }
        }
    } catch (SQLException e) {
        message = "Database error: " + e.getMessage();
        messageType = "error";
        e.printStackTrace();
    } catch (Exception e) {
        message = "Error: " + e.getMessage();
        messageType = "error";
        e.printStackTrace();
    } finally {
        if (pstmt != null) try { pstmt.close(); } catch (SQLException ignored) {}
        if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
    }

    // Redirect back to manage_users.jsp with message
    response.sendRedirect("manage_users.jsp?message=" + java.net.URLEncoder.encode(message, "UTF-8") + "&type=" + messageType);
%>