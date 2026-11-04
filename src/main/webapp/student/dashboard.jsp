<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ include file="../includes/header.jsp" %>
<%
    // Verify student access
    if (!"student".equals(session.getAttribute("role"))) {
        response.sendRedirect("auth/login.jsp");
        return;
    }
    
    int userId = (Integer) session.getAttribute("userId");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Student Dashboard - OpenLibrary</title>
    <link rel="stylesheet" href="../css/style.css">
</head>
<body>
    <div class="container">
        <div class="card">
            <div class="card-header">
                <h2 class="card-title">📚 Welcome, <%= session.getAttribute("username") %>!</h2>
            </div>
            <div class="grid" style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 1rem;">
                <div class="card">
                    <h3>📊 Your Stats</h3>
                    <%
                        Connection conn = null;
                        try {
                            Class.forName("oracle.jdbc.OracleDriver");
                            String url = "jdbc:oracle:thin:@localhost:1521:xe";
                            conn = DriverManager.getConnection(url, "c##library", "1234");
                            
                            Statement stmt = conn.createStatement();
                            
                            // Current loans
                            ResultSet rs = stmt.executeQuery("SELECT COUNT(*) as count FROM c##library.issues WHERE user_id = " + userId + " AND status = 'active'");
                            int currentLoans = 0;
                            if (rs.next()) currentLoans = rs.getInt("count");
                            rs.close();
                            
                            // Overdue books
                            rs = stmt.executeQuery("SELECT COUNT(*) as count FROM c##library.issues WHERE user_id = " + userId + " AND status = 'active' AND due_date < SYSDATE");
                            int overdueBooks = 0;
                            if (rs.next()) overdueBooks = rs.getInt("count");
                            rs.close();
                            
                            // Total borrowed
                            rs = stmt.executeQuery("SELECT COUNT(*) as count FROM c##library.issues WHERE user_id = " + userId);
                            int totalBorrowed = 0;
                            if (rs.next()) totalBorrowed = rs.getInt("count");
                            rs.close();
                            
                            // Fine balance
                            rs = stmt.executeQuery("SELECT COALESCE(SUM(amount), 0) as total_fine FROM c##library.fines f JOIN c##library.issues i ON f.issue_id = i.issue_id WHERE i.user_id = " + userId + " AND f.status = 'pending'");
                            double fineBalance = 0.0;
                            if (rs.next()) fineBalance = rs.getDouble("total_fine");
                            rs.close();
                            
                            stmt.close();
                    %>
                    <p><strong>Current Loans:</strong> <%= currentLoans %>/5</p>
                    <p><strong>Overdue Books:</strong> <%= overdueBooks %></p>
                    <p><strong>Total Borrowed:</strong> <%= totalBorrowed %></p>
                    <p><strong>Fine Balance:</strong> ₹<%= String.format("%.2f", fineBalance) %></p>
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
                        <a href="browse_books.jsp" class="btn btn-primary">Browse Books</a>
                        <a href="my_loans.jsp" class="btn btn-primary">My Loans</a>
                   <!--      <a href="search_books.jsp" class="btn btn-primary">Search Books</a>
                        <a href="reservation_list.jsp" class="btn btn-primary">My Reservations</a> -->
                    </div>
                </div>
                
                                <div class="card">
                    <h3>🔔 Important Dates</h3>
                    <%
                        try {
                            Class.forName("oracle.jdbc.OracleDriver");
                            String url = "jdbc:oracle:thin:@localhost:1521:xe";
                            conn = DriverManager.getConnection(url, "c##library", "1234");
                            
                            PreparedStatement pstmt = conn.prepareStatement(
                                "SELECT * FROM (" +
                                "SELECT b.title, i.due_date, i.due_date - SYSDATE as days_remaining " +
                                "FROM c##library.issues i " +
                                "JOIN c##library.books b ON i.book_id = b.book_id " +
                                "WHERE i.user_id = ? AND i.status = 'active' " +
                                "ORDER BY i.due_date ASC" +
                                ") WHERE ROWNUM <= 5"
                            );
                            pstmt.setInt(1, userId);
                            ResultSet rs = pstmt.executeQuery();
                            
                            while (rs.next()) {
                                int days = rs.getInt("days_remaining");
                                String status = days < 0 ? "OVERDUE!" : (days <= 3 ? "DUE SOON!" : "");
                                String color = days < 0 ? "red" : (days <= 3 ? "orange" : "green");
                                
                                out.println("<p style='color:" + color + ";'>" + 
                                          "<strong>" + rs.getString("title") + "</strong> - Due: " + 
                                          rs.getDate("due_date") + " " + status + "</p>");
                            }
                            rs.close();
                            pstmt.close();
                        } catch (Exception e) {
                            out.println("<p style='color:red;'>Error loading dates: " + e.getMessage() + "</p>");
                        } finally {
                            if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
                        }
                    %>
                </div>
            </div>
        </div>
        
                <div class="card">
            <div class="card-header">
                <h3 class="card-title">📚 Recently Added Books</h3>
            </div>
            <%
                try {
                    Class.forName("oracle.jdbc.OracleDriver");
                    String url = "jdbc:oracle:thin:@localhost:1521:xe";
                    conn = DriverManager.getConnection(url, "c##library", "1234");
                    
                    PreparedStatement pstmt = conn.prepareStatement(
                        "SELECT * FROM (" +
                        "SELECT title, author, category FROM c##library.books ORDER BY added_date DESC" +
                        ") WHERE ROWNUM <= 5"
                    );
                    ResultSet rs = pstmt.executeQuery();
            %>
                    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem;">
            <%
                    while (rs.next()) {
            %>
                        <div class="card" style="padding:1rem; height:auto;">
                            <h4 style="margin:0 0 0.5rem 0;"><%= rs.getString("title") %></h4>
                            <p style="color:var(--text-light); font-size:0.9rem; margin:0 0 0.5rem 0;"><strong>by</strong> <%= rs.getString("author") %></p>
                            <span style="background:var(--bg); padding:0.2rem 0.5rem; border-radius:4px; font-size:0.8rem; margin:0.5rem 0; display:inline-block;">
                                <%= rs.getString("category") %>
                            </span>
                        </div>
            <%
                    }
                    rs.close();
                    pstmt.close();
            %>
                    </div>
            <%
                } catch (Exception e) {
                    out.println("<p style='color:red;'>Error loading recent books: " + e.getMessage() + "</p>");
                } finally {
                    if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
                }
            %>
        </div>
    </div>
    <script src="../js/app.js"></script>
    <%@ include file="../includes/footer.jsp" %>
</body>
</html>