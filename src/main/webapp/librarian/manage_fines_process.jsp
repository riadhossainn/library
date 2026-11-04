<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%
    // Verify librarian access
    if (!"admin".equals(session.getAttribute("role")) && !"librarian".equals(session.getAttribute("role"))) {
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

        if ("pay".equals(action)) {
            String fineIdStr = request.getParameter("fine_id");
            int fineId = Integer.parseInt(fineIdStr);

            // Update fine status to paid
            pstmt = conn.prepareStatement(
                "UPDATE c##library.fines SET status = 'paid', paid_date = SYSDATE WHERE fine_id = ? AND status = 'pending'"
            );
            pstmt.setInt(1, fineId);
            
            int rowsAffected = pstmt.executeUpdate();
            if (rowsAffected > 0) {
                message = "Fine marked as paid successfully!";
                messageType = "success";
            } else {
                message = "Failed to mark fine as paid. It may already be paid or not found.";
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

    // Redirect back to manage_fines.jsp with message
    response.sendRedirect("manage_fines.jsp?message=" + java.net.URLEncoder.encode(message, "UTF-8") + "&type=" + messageType);
%>