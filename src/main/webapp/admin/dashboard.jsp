<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ include file="../includes/header.jsp" %>
<%
    // Verify admin access
    if (!"admin".equals(session.getAttribute("role"))) {
        response.sendRedirect("auth/login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Dashboard - OpenLibrary</title>
    <link rel="stylesheet" href="../css/style.css">
</head>
<body>
    <div class="container">
        <div class="card">
            <div class="card-header">
                <h2 class="card-title">📚 Admin Dashboard</h2>
            </div>
            <div class="grid" style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 1rem;">
                <div class="card">
                    <h3>📊 System Stats</h3>
                    <%
                        Connection conn = null;
                        try {
                            Class.forName("oracle.jdbc.OracleDriver");
                            String url = "jdbc:oracle:thin:@localhost:1521:xe";
                            conn = DriverManager.getConnection(url, "c##library", "1234");
                            
                            Statement stmt = conn.createStatement();
                            
                            ResultSet rs = stmt.executeQuery("SELECT COUNT(*) as count FROM c##library.users");
                            int totalUsers = 0;
                            if (rs.next()) totalUsers = rs.getInt("count");
                            rs.close();
                            
                            rs = stmt.executeQuery("SELECT COUNT(*) as count FROM c##library.books");
                            int totalBooks = 0;
                            if (rs.next()) totalBooks = rs.getInt("count");
                            rs.close();
                            
                            rs = stmt.executeQuery("SELECT COUNT(*) as count FROM c##library.issues WHERE status = 'active'");
                            int activeLoans = 0;
                            if (rs.next()) activeLoans = rs.getInt("count");
                            rs.close();
                            
                            rs = stmt.executeQuery("SELECT COUNT(*) as count FROM c##library.fines WHERE status = 'pending'");
                            int pendingFines = 0;
                            if (rs.next()) pendingFines = rs.getInt("count");
                            rs.close();
                            
                            rs = stmt.executeQuery("SELECT COUNT(*) as count FROM c##library.issues WHERE status = 'active' AND due_date < SYSDATE");
                            int overdueBooks = 0;
                            if (rs.next()) overdueBooks = rs.getInt("count");
                            rs.close();
                            
                            stmt.close();
                    %>
                    <p><strong>Total Users:</strong> <%= totalUsers %></p>
                    <p><strong>Total Books:</strong> <%= totalBooks %></p>
                    <p><strong>Active Loans:</strong> <%= activeLoans %></p>
                    <p><strong>Overdue Items:</strong> <%= overdueBooks %></p>
                    <p><strong>Pending Fines:</strong> <%= pendingFines %></p>
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
                 <a href="manage_users.jsp" class="btn btn-primary">Manage Users</a>
               <a href="reports.jsp" class="btn btn-primary">Generate Reports</a>
               <a href="system_maintenance.jsp" class="btn btn-primary">System Maintenance</a>
              <!-- These links now work for admin since they're in the header -->
               <a href="../librarian/manage_books.jsp" class="btn btn-primary">Manage Books</a>
               <a href="../librarian/process_loans.jsp" class="btn btn-primary">Process Loans</a>
                <a href="../librarian/manage_fines.jsp" class="btn btn-primary">Manage Fines</a>
               </div>
            </div>
                
                <div class="card">
                    <h3>🔔 Recent Activity</h3>
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
                                ") WHERE ROWNUM <= 5"
                            );
                            ResultSet rs = pstmt.executeQuery();
                            
                            while (rs.next()) {
                                out.println("<p><strong>" + rs.getString("username") + "</strong> borrowed " + 
                                          "<em>" + rs.getString("title") + "</em> - " + 
                                          rs.getDate("issue_date") + "</p>");
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
        
        <div class="card">
            <div class="card-header">
                <h3 class="card-title">💰 Recent Fines</h3>
            </div>
            <table class="table">
                <thead>
                    <tr>
                        <th>Student</th>
                        <th>Book Title</th>
                        <th>Amount</th>
                        <th>Date</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    <%
                        try {
                            Class.forName("oracle.jdbc.OracleDriver");
                            String url = "jdbc:oracle:thin:@localhost:1521:xe";
                            conn = DriverManager.getConnection(url, "c##library", "1234");
                            
                            PreparedStatement pstmt = conn.prepareStatement(
                                "SELECT * FROM (" +
                                "SELECT u.username, b.title, f.amount, f.fine_date, f.status " +
                                "FROM c##library.fines f " +
                                "JOIN c##library.issues i ON f.issue_id = i.issue_id " +
                                "JOIN c##library.users u ON i.user_id = u.user_id " +
                                "JOIN c##library.books b ON i.book_id = b.book_id " +
                                "ORDER BY f.fine_date DESC" +
                                ") WHERE ROWNUM <= 5"
                            );
                            ResultSet rs = pstmt.executeQuery();
                            
                            while (rs.next()) {
                    %>
                                <tr>
                                    <td><%= rs.getString("username") %></td>
                                    <td><%= rs.getString("title") %></td>
                                    <td>₹<%= rs.getDouble("amount") %></td>
                                    <td><%= rs.getDate("fine_date") %></td>
                                    <td><span style="background:<%= 
                                        "paid".equals(rs.getString("status")) ? "#dcfce7;" : "#fee2e2;" 
                                    %> padding:0.2rem 0.5rem; border-radius:4px; color:black;">
                                        <%= rs.getString("status") %>
                                    </span></td>
                                </tr>
                    <%
                            }
                            rs.close();
                            pstmt.close();
                        } catch (Exception e) {
                            out.println("<tr><td colspan='5' style='color:red;'>Error loading fines: " + e.getMessage() + "</td></tr>");
                        } finally {
                            if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
                        }
                    %>
                </tbody>
            </table>
        </div>
    </div>
    
    <script src="../js/app.js"></script>
    <%@ include file="../includes/footer.jsp" %>
</body>
</html>