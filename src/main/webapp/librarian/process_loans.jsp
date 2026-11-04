<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, java.util.Date, java.text.SimpleDateFormat" %>
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
    <title>Process Loans - OpenLibrary</title>
    <link rel="stylesheet" href="../css/style.css">
</head>
<body>
    <div class="container">
        <div class="card">
            <div class="card-header">
                <h2 class="card-title">📚 Process Book Loans</h2>
            </div>
            
            <!-- Message Display -->
            <% if (message != null) { %>
                <div class="alert alert-<%= messageType != null ? messageType : "info" %>">
                    <%= message %>
                </div>
            <% } %>
            
            <!-- Loan Form -->
            <form method="post" action="process_loans_process.jsp" class="grid" style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 1rem; margin-bottom: 2rem;">
                <div class="form-group">
                    <label>Student Username *</label>
                    <input type="text" name="username" placeholder="Enter student username" required>
                </div>
                
                <div class="form-group">
                    <label>Book ID *</label>
                    <input type="number" name="book_id" placeholder="Enter book ID" required>
                </div>
                
                <div class="form-group">
                    <label>Due Date *</label>
                    <input type="date" name="due_date" required>
                </div>
                
                <div style="align-self: end;">
                    <button type="submit" name="action" value="issue" class="btn btn-primary">Issue Book</button>
                </div>
            </form>
            
            <!-- Current Loans Table -->
            <div class="card">
                <div class="card-header">
                    <h3 class="card-title">Current Active Loans</h3>
                </div>
                <table class="table">
                    <thead>
                        <tr>
                            <th>Loan ID</th>
                            <th>Student</th>
                            <th>Book Title</th>
                            <th>Issue Date</th>
                            <th>Due Date</th>
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
                                    "SELECT i.issue_id, u.username, b.title, i.issue_date, i.due_date, i.status " +
                                    "FROM c##library.issues i " +
                                    "JOIN c##library.users u ON i.user_id = u.user_id " +
                                    "JOIN c##library.books b ON i.book_id = b.book_id " +
                                    "WHERE i.status = 'active' " +
                                    "ORDER BY i.issue_date DESC"
                                );
                                ResultSet rs = pstmt.executeQuery();
                                
                                while (rs.next()) {
                        %>
                                    <tr>
                                        <td><%= rs.getInt("issue_id") %></td>
                                        <td><%= rs.getString("username") %></td>
                                        <td><%= rs.getString("title") %></td>
                                        <td><%= rs.getDate("issue_date") %></td>
                                        <td><%= rs.getDate("due_date") %></td>
                                        <td><span style="background: #dcfce7; padding: 0.2rem 0.5rem; border-radius: 4px; color: black;">Active</span></td>
                                        <td>
                                            <form method="post" action="process_loans_process.jsp" style="display: inline;">
                                                <input type="hidden" name="issue_id" value="<%= rs.getInt("issue_id") %>">
                                                <input type="hidden" name="action" value="return">
                                                <button type="submit" class="btn btn-sm btn-primary">Return</button>
                                            </form>
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
        </div>
    </div>

    <script src="../js/app.js"></script>
    <script>
        // Set default due date to 14 days from today
        document.addEventListener('DOMContentLoaded', function() {
            const today = new Date();
            const dueDate = new Date(today);
            dueDate.setDate(dueDate.getDate() + 14); // 14 days loan period
            
            const formattedDate = dueDate.toISOString().split('T')[0];
            const dueDateInput = document.querySelector('input[name="due_date"]');
            if (dueDateInput && !dueDateInput.value) {
                dueDateInput.value = formattedDate;
            }
        });
    </script>
    <%@ include file="../includes/footer.jsp" %>
</body>
</html>