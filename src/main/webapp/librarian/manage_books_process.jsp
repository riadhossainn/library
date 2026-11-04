<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%
    // Verify admin or librarian access
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

        if ("delete".equals(action)) {
            String bookIdStr = request.getParameter("book_id");
            int bookId = Integer.parseInt(bookIdStr);

            // Check if book exists
            pstmt = conn.prepareStatement("SELECT COUNT(*) as count FROM c##library.books WHERE book_id = ?");
            pstmt.setInt(1, bookId);
            ResultSet rs = pstmt.executeQuery();
            boolean exists = false;
            if (rs.next()) exists = rs.getInt("count") > 0;
            rs.close();
            
            if (exists) {
                pstmt = conn.prepareStatement("DELETE FROM c##library.books WHERE book_id = ?");
                pstmt.setInt(1, bookId);
                
                int rowsAffected = pstmt.executeUpdate();
                if (rowsAffected > 0) {
                    message = "Book deleted successfully!";
                    messageType = "success";
                } else {
                    message = "Failed to delete book.";
                    messageType = "error";
                }
            } else {
                message = "Book not found.";
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

    // Redirect back to manage_books.jsp with message
    response.sendRedirect("manage_books.jsp?message=" + java.net.URLEncoder.encode(message, "UTF-8") + "&type=" + messageType);
%>