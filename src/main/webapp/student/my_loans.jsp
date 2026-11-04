<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, java.text.SimpleDateFormat, java.util.Date" %>
<%@ include file="../includes/header.jsp" %>
<%
    // Verify student access
    if (!"student".equals(session.getAttribute("role"))) {
        response.sendRedirect("../auth/login.jsp");
        return;
    }
    
    int userId = (Integer) session.getAttribute("userId");
    String message = request.getParameter("message");
    String messageType = request.getParameter("type");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Loans - OpenLibrary</title>
    <link rel="stylesheet" href="../css/style.css">
</head>
<body>
    <div class="container">
        <div class="card">
            <div class="card-header">
                <h2 class="card-title">📚 My Loan History</h2>
            </div>
            
            <!-- Message Display -->
            <% if (message != null) { %>
                <div class="alert alert-<%= messageType != null ? messageType : "info" %>">
                    <%= message %>
                </div>
            <% } %>
            
            <!-- Loan Requests -->
            <div class="card">
                <div class="card-header">
                    <h3 class="card-title">📋 My Loan Requests</h3>
                </div>
                <table class="table">
                    <thead>
                        <tr>
                            <th>Book Title</th>
                            <th>Author</th>
                            <th>Request Date</th>
                            <th>Status</th>
                            <th>Notes</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                            Connection conn = null;
                            try {
                                Class.forName("oracle.jdbc.OracleDriver");
                                String url = "jdbc:oracle:thin:@localhost:1521:xe";
                                conn = DriverManager.getConnection(url, "c##library", "1234");
                                
                                PreparedStatement pstmt = conn.prepareStatement(
                                    "SELECT lr.status, b.title, b.author, lr.request_date, lr.notes " +
                                    "FROM c##library.loan_requests lr " +
                                    "JOIN c##library.books b ON lr.book_id = b.book_id " +
                                    "WHERE lr.user_id = ? " +
                                    "ORDER BY lr.request_date DESC"
                                );
                                pstmt.setInt(1, userId);
                                ResultSet rs = pstmt.executeQuery();
                                
                                while (rs.next()) {
                        %>
                                    <tr>
                                        <td><%= rs.getString("title") %></td>
                                        <td><%= rs.getString("author") %></td>
                                        <td><%= rs.getDate("request_date") %></td>
                                        <td>
                                            <span style="background:<%= 
                                                "approved".equals(rs.getString("status")) ? "#dcfce7;" : 
                                                "pending".equals(rs.getString("status")) ? "#fef3c7;" : "#fee2e2;" 
                                            %> padding:0.2rem 0.5rem; border-radius:4px; color:black;">
                                                <%= rs.getString("status") %>
                                            </span>
                                        </td>
                                        <td><%= rs.getString("notes") != null ? rs.getString("notes") : "-" %></td>
                                    </tr>
                        <%
                                }
                                rs.close();
                                pstmt.close();
                            } catch (Exception e) {
                                out.println("<tr><td colspan='5' style='color:red;'>Error loading requests: " + e.getMessage() + "</td></tr>");
                            } finally {
                                if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
                            }
                        %>
                    </tbody>
                </table>
            </div>
            
            <!-- Current Loans -->
            <div class="card">
                <div class="card-header">
                    <h3 class="card-title">Current Active Loans</h3>
                </div>
                <table class="table">
                    <thead>
                        <tr>
                            <th>Book Title</th>
                            <th>Author</th>
                            <th>Issue Date</th>
                            <th>Due Date</th>
                            <th>Days Remaining</th>
                            <th>Status</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                            try {
                                Class.forName("oracle.jdbc.OracleDriver");
                                String url = "jdbc:oracle:thin:@localhost:1521:xe";
                                conn = DriverManager.getConnection(url, "c##library", "1234");
                                
                                PreparedStatement pstmt = conn.prepareStatement(
                                    "SELECT i.issue_id, b.title, b.author, i.issue_date, i.due_date, i.status " +
                                    "FROM c##library.issues i " +
                                    "JOIN c##library.books b ON i.book_id = b.book_id " +
                                    "WHERE i.user_id = ? AND i.status = 'active' " +
                                    "ORDER BY i.due_date ASC"
                                );
                                pstmt.setInt(1, userId);
                                ResultSet rs = pstmt.executeQuery();
                                
                                SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
                                Date today = new Date();
                                
                                while (rs.next()) {
                                    Date dueDate = rs.getDate("due_date");
                                    long diffInMillies = dueDate.getTime() - today.getTime();
                                    long daysRemaining = diffInMillies / (24 * 60 * 60 * 1000);
                                    
                                    String statusColor = "green";
                                    String statusText = "Active";
                                    if (daysRemaining < 0) {
                                        statusColor = "red";
                                        statusText = "Overdue";
                                    } else if (daysRemaining <= 3) {
                                        statusColor = "orange";
                                        statusText = "Due Soon";
                                    }
                        %>
                                    <tr>
                                        <td><%= rs.getString("title") %></td>
                                        <td><%= rs.getString("author") %></td>
                                        <td><%= rs.getDate("issue_date") %></td>
                                        <td><%= rs.getDate("due_date") %></td>
                                        <td>
                                            <span style="color: <%= statusColor %>;">
                                                <%= daysRemaining >= 0 ? "+" + daysRemaining : daysRemaining %> days
                                            </span>
                                        </td>
                                        <td>
                                            <span style="background:<%= 
                                                daysRemaining < 0 ? "#fee2e2;" : 
                                                daysRemaining <= 3 ? "#fed7aa;" : "#dcfce7;" 
                                            %> padding:0.2rem 0.5rem; border-radius:4px; color:black;">
                                                <%= statusText %>
                                            </span>
                                        </td>
                                        <td>
                                            <button onclick="requestReturn(<%= rs.getInt("issue_id") %>)" class="btn btn-sm btn-primary">Request Return</button>
                                        </td>
                                    </tr>
                        <%
                                }
                                rs.close();
                                pstmt.close();
                            } catch (Exception e) {
                                out.println("<tr><td colspan='7' style='color:red;'>Error loading loans: " + e.getMessage() + "</td></tr>");
                            } finally {
                                if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
                            }
                        %>
                    </tbody>
                </table>
            </div>
            
            <!-- Past Loans -->
            <div class="card">
                <div class="card-header">
                    <h3 class="card-title">Past Loans</h3>
                </div>
                <table class="table">
                    <thead>
                        <tr>
                            <th>Book Title</th>
                            <th>Issue Date</th>
                            <th>Due Date</th>
                            <th>Return Date</th>
                            <th>Fine Paid</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                            try {
                                Class.forName("oracle.jdbc.OracleDriver");
                                String url = "jdbc:oracle:thin:@localhost:1521:xe";
                                conn = DriverManager.getConnection(url, "c##library", "1234");
                                
                                PreparedStatement pstmt = conn.prepareStatement(
                                    "SELECT i.issue_id, b.title, i.issue_date, i.due_date, i.return_date, " +
                                    "COALESCE(f.amount, 0) as fine_amount " +
                                    "FROM c##library.issues i " +
                                    "JOIN c##library.books b ON i.book_id = b.book_id " +
                                    "LEFT JOIN c##library.fines f ON i.issue_id = f.issue_id " +
                                    "WHERE i.user_id = ? AND i.status = 'returned' " +
                                    "ORDER BY i.return_date DESC"
                                );
                                pstmt.setInt(1, userId);
                                ResultSet rs = pstmt.executeQuery();
                                
                                while (rs.next()) {
                        %>
                                    <tr>
                                        <td><%= rs.getString("title") %></td>
                                        <td><%= rs.getDate("issue_date") %></td>
                                        <td><%= rs.getDate("due_date") %></td>
                                        <td><%= rs.getDate("return_date") %></td>
                                        <td>₹<%= rs.getDouble("fine_amount") %></td>
                                    </tr>
                        <%
                                }
                                rs.close();
                                pstmt.close();
                            } catch (Exception e) {
                                out.println("<tr><td colspan='5' style='color:red;'>Error loading past loans: " + e.getMessage() + "</td></tr>");
                            } finally {
                                if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
                            }
                        %>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <script src="../js/app.js"></script>
    <script>
        function requestReturn(issueId) {
            if (confirm('Are you sure you want to request return for this book?')) {
                // In a real system, this would create a return request
                // For now, just show a confirmation
                OpenLibrary.showNotification('Return request sent for loan ID: ' + issueId, 'success');
            }
        }
    </script>
    <%@ include file="../includes/footer.jsp" %>
</body>
</html>