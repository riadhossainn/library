<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ include file="../includes/header.jsp" %>

<%
    // Verify librarian access
    if (!"librarian".equals(session.getAttribute("role"))) {
        response.sendRedirect("auth/login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Librarian Dashboard - OpenLibrary</title>
    <link rel="stylesheet" href="../css/style.css">
</head>
<body>
    <div class="container">
        <div class="card">
            <div class="card-header">
                <h2 class="card-title">📚 Librarian Dashboard</h2>
            </div>
            <div class="grid" style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 1rem;">
                <div class="card">
                    <h3>📊 Inventory Stats</h3>
                    <%
                        Connection conn = null;
                        try {
                            Class.forName("oracle.jdbc.OracleDriver");
                            String url = "jdbc:oracle:thin:@localhost:1521:xe";
                            conn = DriverManager.getConnection(url, "c##library", "1234");
                            
                            Statement stmt = conn.createStatement();
                            
                            // Total books
                            ResultSet rs = stmt.executeQuery("SELECT COUNT(*) as count FROM c##library.books");
                            int totalBooks = 0;
                            if (rs.next()) totalBooks = rs.getInt("count");
                            rs.close();
                            
                            // Available books
                            rs = stmt.executeQuery("SELECT SUM(available_copies) as total_available FROM c##library.books");
                            int availableBooks = 0;
                            if (rs.next()) availableBooks = rs.getInt("total_available");
                            rs.close();
                            
                            // Borrowed books
                            rs = stmt.executeQuery("SELECT SUM(total_copies - available_copies) as total_borrowed FROM c##library.books");
                            int borrowedBooks = 0;
                            if (rs.next()) borrowedBooks = rs.getInt("total_borrowed");
                            rs.close();
                            
                            // Overdue items
                            rs = stmt.executeQuery("SELECT COUNT(*) as count FROM c##library.issues WHERE status = 'active' AND due_date < SYSDATE");
                            int overdueItems = 0;
                            if (rs.next()) overdueItems = rs.getInt("count");
                            rs.close();
                            
                            stmt.close();
                    %>
                    <p><strong>Total Books:</strong> <%= totalBooks %></p>
                    <p><strong>Available Books:</strong> <%= availableBooks %></p>
                    <p><strong>Borrowed Books:</strong> <%= borrowedBooks %></p>
                    <p><strong>Overdue Items:</strong> <%= overdueItems %></p>
                    <%
                        } catch (Exception e) {
                            out.println("<p style='color:red;'>Error loading stats: " + e.getMessage() + "</p>");
                        } finally {
                            if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
                        }
                    %>
                </div>
                
                <div class="card">
                    <h3>⚡ Quick Actions</h3>
                    <div style="display: flex; flex-direction: column; gap: 0.5rem;">
                        <a href="manage_books.jsp" class="btn btn-primary">Manage Books</a>
                        <a href="process_loans.jsp" class="btn btn-primary">Process Loans</a>
                        <a href="process_returns.jsp" class="btn btn-primary">Process Returns</a>
                        <a href="manage_fines.jsp" class="btn btn-primary">Manage Fines</a>
                    </div>
                </div>
                
                <div class="card">
                    <h3>🔔 Today's Tasks</h3>
                    <%
                        try {
                            Class.forName("oracle.jdbc.OracleDriver");
                            String url = "jdbc:oracle:thin:@localhost:1521:xe";
                            conn = DriverManager.getConnection(url, "c##library", "1234");
                            
                            Statement stmt = conn.createStatement();
                            
                            // Today's issues
                            ResultSet rs = stmt.executeQuery("SELECT COUNT(*) as count FROM c##library.issues WHERE TRUNC(issue_date) = TRUNC(SYSDATE)");
                            int todayIssues = 0;
                            if (rs.next()) todayIssues = rs.getInt("count");
                            rs.close();
                            
                            // Today's returns
                            rs = stmt.executeQuery("SELECT COUNT(*) as count FROM c##library.issues WHERE return_date IS NOT NULL AND TRUNC(return_date) = TRUNC(SYSDATE)");
                            int todayReturns = 0;
                            if (rs.next()) todayReturns = rs.getInt("count");
                            rs.close();
                            
                            stmt.close();
                    %>
                    <ul style="list-style: none; padding: 0;">
                        <li>• Process new book arrivals</li>
                        <li>• Handle loan requests</li>
                        <li>• Update overdue notices</li>
                        <li>• Generate daily report</li>
                        <li>• Today's issues: <%= todayIssues %></li>
                        <li>• Today's returns: <%= todayReturns %></li>
                    </ul>
                    <%
                        } catch (Exception e) {
                            out.println("<p style='color:red;'>Error loading tasks: " + e.getMessage() + "</p>");
                        } finally {
                            if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
                        }
                    %>
                </div>
            </div>
        </div>
        
               <div class="card">
            <div class="card-header">
                <h3 class="card-title">📅 Recent Activity</h3>
            </div>
            <div id="activity-feed">
                <%
                    try {
                        Class.forName("oracle.jdbc.OracleDriver");
                        String url = "jdbc:oracle:thin:@localhost:1521:xe";
                        conn = DriverManager.getConnection(url, "c##library", "1234");
                        
                        PreparedStatement pstmt = conn.prepareStatement(
                            "SELECT * FROM (" +
                            "SELECT u.username, b.title, i.issue_date, i.status " +
                            "FROM c##library.issues i " +
                            "JOIN c##library.users u ON i.user_id = u.user_id " +
                            "JOIN c##library.books b ON i.book_id = b.book_id " +
                            "ORDER BY i.issue_date DESC" +
                            ") WHERE ROWNUM <= 10"
                        );
                        ResultSet rs = pstmt.executeQuery();
                        
                        while (rs.next()) {
                            out.println("<p><strong>" + rs.getString("username") + "</strong> borrowed " + 
                                      "<em>" + rs.getString("title") + "</em> - " + 
                                      rs.getDate("issue_date") + " (" + rs.getString("status") + ")</p>");
                        }
                        rs.close();
                        pstmt.close();
                    } catch (Exception e) {
                        out.println("<p style='color:red;'>Error loading activity: " + e.getMessage() + "</p>");
                    } finally {
                        if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
                    }
                %>
            </div>
        </div>
    </div>
    <script src="../js/app.js"></script>
    <%@ include file="../includes/footer.jsp" %>
</body>
</html>