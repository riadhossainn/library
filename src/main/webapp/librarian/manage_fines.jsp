<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, java.text.SimpleDateFormat" %>
<%@ include file="../includes/header.jsp" %>
<%
    // Allow admin and librarian access (role is already defined in header.jsp)
    if (!"admin".equals((String) session.getAttribute("role")) && !"librarian".equals((String) session.getAttribute("role"))) {
        response.sendRedirect("../auth/login.jsp");
        return;
    }
    
    String message = request.getParameter("message");
    String messageType = request.getParameter("type");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manage Fines - OpenLibrary</title>
    <link rel="stylesheet" href="../css/style.css">
</head>
<body>
    <div class="container">
        <div class="card">
            <div class="card-header">
                <h2 class="card-title">💰 Manage Fines</h2>
            </div>
            
            <!-- Message Display -->
            <% if (message != null) { %>
                <div class="alert alert-<%= messageType != null ? messageType : "info" %>">
                    <%= message %>
                </div>
            <% } %>
            
            <!-- Pending Fines Table -->
            <div class="card">
                <div class="card-header">
                    <h3 class="card-title">Pending Fines</h3>
                </div>
                <table class="table">
                    <thead>
                        <tr>
                            <th>Fine ID</th>
                            <th>Student</th>
                            <th>Book Title</th>
                            <th>Issue Date</th>
                            <th>Fine Amount</th>
                            <th>Fine Date</th>
                            <th>Status</th>
                            <th>Actions</th>
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
                                    "SELECT f.fine_id, u.username, b.title, i.issue_date, f.amount, f.fine_date, f.status " +
                                    "FROM c##library.fines f " +
                                    "JOIN c##library.issues i ON f.issue_id = i.issue_id " +
                                    "JOIN c##library.users u ON i.user_id = u.user_id " +
                                    "JOIN c##library.books b ON i.book_id = b.book_id " +
                                    "WHERE f.status = 'pending' " +
                                    "ORDER BY f.fine_date DESC"
                                );
                                ResultSet rs = pstmt.executeQuery();
                                
                                while (rs.next()) {
                        %>
                                    <tr>
                                        <td><%= rs.getInt("fine_id") %></td>
                                        <td><%= rs.getString("username") %></td>
                                        <td><%= rs.getString("title") %></td>
                                        <td><%= rs.getDate("issue_date") %></td>
                                        <td>₹<%= rs.getDouble("amount") %></td>
                                        <td><%= rs.getDate("fine_date") %></td>
                                        <td><span style="background: #fee2e2; padding: 0.2rem 0.5rem; border-radius: 4px; color: black;">Pending</span></td>
                                        <td>
                                            <form method="post" action="manage_fines_process.jsp" style="display: inline;">
                                                <input type="hidden" name="fine_id" value="<%= rs.getInt("fine_id") %>">
                                                <input type="hidden" name="action" value="pay">
                                                <button type="submit" class="btn btn-sm btn-primary">Mark Paid</button>
                                            </form>
                                        </td>
                                    </tr>
                        <%
                                }
                                rs.close();
                                pstmt.close();
                            } catch (Exception e) {
                                out.println("<tr><td colspan='8' style='color:red;'>Error loading fines: " + e.getMessage() + "</td></tr>");
                            } finally {
                                if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
                            }
                        %>
                    </tbody>
                </table>
            </div>
            
            <!-- Paid Fines Table -->
            <div class="card">
                <div class="card-header">
                    <h3 class="card-title">Paid Fines</h3>
                </div>
                <table class="table">
                    <thead>
                        <tr>
                            <th>Fine ID</th>
                            <th>Student</th>
                            <th>Book Title</th>
                            <th>Fine Amount</th>
                            <th>Fine Date</th>
                            <th>Paid Date</th>
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
                                    "SELECT f.fine_id, u.username, b.title, f.amount, f.fine_date, f.paid_date, f.status " +
                                    "FROM c##library.fines f " +
                                    "JOIN c##library.issues i ON f.issue_id = i.issue_id " +
                                    "JOIN c##library.users u ON i.user_id = u.user_id " +
                                    "JOIN c##library.books b ON i.book_id = b.book_id " +
                                    "WHERE f.status = 'paid' " +
                                    "ORDER BY f.paid_date DESC"
                                );
                                ResultSet rs = pstmt.executeQuery();
                                
                                while (rs.next()) {
                        %>
                                    <tr>
                                        <td><%= rs.getInt("fine_id") %></td>
                                        <td><%= rs.getString("username") %></td>
                                        <td><%= rs.getString("title") %></td>
                                        <td>₹<%= rs.getDouble("amount") %></td>
                                        <td><%= rs.getDate("fine_date") %></td>
                                        <td><%= rs.getDate("paid_date") %></td>
                                        <td><span style="background: #dcfce7; padding: 0.2rem 0.5rem; border-radius: 4px; color: black;">Paid</span></td>
                                    </tr>
                        <%
                                }
                                rs.close();
                                pstmt.close();
                            } catch (Exception e) {
                                out.println("<tr><td colspan='7' style='color:red;'>Error loading paid fines: " + e.getMessage() + "</td></tr>");
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
    <%@ include file="../includes/footer.jsp" %>
</body>
</html>