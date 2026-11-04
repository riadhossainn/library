<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, java.text.SimpleDateFormat, java.util.Date" %>
<%@ include file="../includes/header.jsp" %>
<%
    // Verify admin access
    if (!"admin".equals(session.getAttribute("role"))) {
        response.sendRedirect("../auth/login.jsp");
        return;
    }
    
    String reportType = request.getParameter("report_type");
    String startDate = request.getParameter("start_date");
    String endDate = request.getParameter("end_date");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reports - OpenLibrary</title>
    <link rel="stylesheet" href="../css/style.css">
</head>
<body>
    <div class="container">
        <div class="card">
            <div class="card-header">
                <h2 class="card-title">📊 Reports</h2>
            </div>
            
            <!-- Report Selection Form -->
            <form method="get" class="grid" style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem; margin-bottom: 2rem;">
                <div class="form-group">
                    <label>Report Type</label>
                    <select name="report_type" onchange="this.form.submit()">
                        <option value="">Select Report Type</option>
                        <option value="user_activity" <%= "user_activity".equals(reportType) ? "selected" : "" %>>User Activity</option>
                        <option value="book_borrowing" <%= "book_borrowing".equals(reportType) ? "selected" : "" %>>Book Borrowing</option>
                        <option value="overdue_books" <%= "overdue_books".equals(reportType) ? "selected" : "" %>>Overdue Books</option>
                        <option value="fine_collection" <%= "fine_collection".equals(reportType) ? "selected" : "" %>>Fine Collection</option>
                        <option value="inventory_status" <%= "inventory_status".equals(reportType) ? "selected" : "" %>>Inventory Status</option>
                    </select>
                </div>
                
                <div class="form-group">
                    <label>Start Date</label>
                    <input type="date" name="start_date" value="<%= startDate != null ? startDate : "" %>">
                </div>
                
                <div class="form-group">
                    <label>End Date</label>
                    <input type="date" name="end_date" value="<%= endDate != null ? endDate : "" %>">
                </div>
                
               <div style="align-self: end; text-align: center;">
                 <button type="button" onclick="printReport()" class="btn btn-primary" style="background: linear-gradient(135deg, #3b82f6, #1d4ed8); border: none; padding: 0.5rem 1rem; border-radius: 6px; color: white; cursor: pointer;">🖨️ Print Report</button>
               </div>
            </form>
            
            <!-- Report Results -->
            <div id="reportContent">
                <%
                    if (reportType != null) {
                        Connection conn = null;
                        try {
                            Class.forName("oracle.jdbc.OracleDriver");
                            String url = "jdbc:oracle:thin:@localhost:1521:xe";
                            conn = DriverManager.getConnection(url, "c##library", "1234");
                            
                            if ("user_activity".equals(reportType)) {
                                // User Activity Report
                                String sql = "SELECT u.username, u.name, u.role, COUNT(i.issue_id) as loans_count " +
                                           "FROM c##library.users u " +
                                           "LEFT JOIN c##library.issues i ON u.user_id = i.user_id " +
                                           "GROUP BY u.user_id, u.username, u.name, u.role " +
                                           "ORDER BY loans_count DESC";
                                
                                PreparedStatement pstmt = conn.prepareStatement(sql);
                                ResultSet rs = pstmt.executeQuery();
                %>
                                <h3>User Activity Report</h3>
                                <table class="table">
                                    <thead>
                                        <tr>
                                            <th>Username</th>
                                            <th>Name</th>
                                            <th>Role</th>
                                            <th>Total Loans</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                <%
                                while (rs.next()) {
                %>
                                    <tr>
                                        <td><%= rs.getString("username") %></td>
                                        <td><%= rs.getString("name") %></td>
                                        <td><%= rs.getString("role") %></td>
                                        <td><%= rs.getInt("loans_count") %></td>
                                    </tr>
                <%
                                }
                                rs.close();
                                pstmt.close();
                %>
                                    </tbody>
                                </table>
                <%
                            }
                            else if ("book_borrowing".equals(reportType)) {
                                // Book Borrowing Report
                                String sql = "SELECT b.title, b.author, COUNT(i.issue_id) as times_borrowed " +
                                           "FROM c##library.books b " +
                                           "LEFT JOIN c##library.issues i ON b.book_id = i.book_id " +
                                           "GROUP BY b.book_id, b.title, b.author " +
                                           "ORDER BY times_borrowed DESC";
                                
                                PreparedStatement pstmt = conn.prepareStatement(sql);
                                ResultSet rs = pstmt.executeQuery();
                %>
                                <h3>Book Borrowing Report</h3>
                                <table class="table">
                                    <thead>
                                        <tr>
                                            <th>Book Title</th>
                                            <th>Author</th>
                                            <th>Times Borrowed</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                <%
                                while (rs.next()) {
                %>
                                    <tr>
                                        <td><%= rs.getString("title") %></td>
                                        <td><%= rs.getString("author") %></td>
                                        <td><%= rs.getInt("times_borrowed") %></td>
                                    </tr>
                <%
                                }
                                rs.close();
                                pstmt.close();
                %>
                                    </tbody>
                                </table>
                <%
                            }
                            else if ("overdue_books".equals(reportType)) {
                                // Overdue Books Report
                                String sql = "SELECT u.username, b.title, i.issue_date, i.due_date, " +
                                           "SYSDATE - i.due_date as days_overdue " +
                                           "FROM c##library.issues i " +
                                           "JOIN c##library.users u ON i.user_id = u.user_id " +
                                           "JOIN c##library.books b ON i.book_id = b.book_id " +
                                           "WHERE i.status = 'active' AND i.due_date < SYSDATE " +
                                           "ORDER BY days_overdue DESC";
                                
                                PreparedStatement pstmt = conn.prepareStatement(sql);
                                ResultSet rs = pstmt.executeQuery();
                %>
                                <h3>Overdue Books Report</h3>
                                <table class="table">
                                    <thead>
                                        <tr>
                                            <th>Student</th>
                                            <th>Book Title</th>
                                            <th>Issue Date</th>
                                            <th>Due Date</th>
                                            <th>Days Overdue</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                <%
                                while (rs.next()) {
                %>
                                    <tr>
                                        <td><%= rs.getString("username") %></td>
                                        <td><%= rs.getString("title") %></td>
                                        <td><%= rs.getDate("issue_date") %></td>
                                        <td><%= rs.getDate("due_date") %></td>
                                        <td style="color: red; font-weight: bold;"><%= rs.getInt("days_overdue") %> days</td>
                                    </tr>
                <%
                                }
                                rs.close();
                                pstmt.close();
                %>
                                    </tbody>
                                </table>
                <%
                            }
                            else if ("fine_collection".equals(reportType)) {
                                // Fine Collection Report
                                String sql = "SELECT f.fine_id, u.username, b.title, f.amount, f.fine_date, f.status " +
                                           "FROM c##library.fines f " +
                                           "JOIN c##library.issues i ON f.issue_id = i.issue_id " +
                                           "JOIN c##library.users u ON i.user_id = u.user_id " +
                                           "JOIN c##library.books b ON i.book_id = b.book_id " +
                                           "ORDER BY f.fine_date DESC";
                                
                                PreparedStatement pstmt = conn.prepareStatement(sql);
                                ResultSet rs = pstmt.executeQuery();
                %>
                                <h3>Fine Collection Report</h3>
                                <table class="table">
                                    <thead>
                                        <tr>
                                            <th>Fine ID</th>
                                            <th>Student</th>
                                            <th>Book Title</th>
                                            <th>Amount</th>
                                            <th>Date</th>
                                            <th>Status</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                <%
                                while (rs.next()) {
                %>
                                    <tr>
                                        <td><%= rs.getInt("fine_id") %></td>
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
                %>
                                    </tbody>
                                </table>
                <%
                            }
                            else if ("inventory_status".equals(reportType)) {
                                // Inventory Status Report
                                String sql = "SELECT b.title, b.author, b.total_copies, b.available_copies, " +
                                           "(b.total_copies - b.available_copies) as borrowed_copies " +
                                           "FROM c##library.books b " +
                                           "ORDER BY b.title";
                                
                                PreparedStatement pstmt = conn.prepareStatement(sql);
                                ResultSet rs = pstmt.executeQuery();
                %>
                                <h3>Inventory Status Report</h3>
                                <table class="table">
                                    <thead>
                                        <tr>
                                            <th>Book Title</th>
                                            <th>Author</th>
                                            <th>Total Copies</th>
                                            <th>Available</th>
                                            <th>Borrowed</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                <%
                                while (rs.next()) {
                                    int total = rs.getInt("total_copies");
                                    int available = rs.getInt("available_copies");
                                    int borrowed = total - available;
                %>
                                    <tr>
                                        <td><%= rs.getString("title") %></td>
                                        <td><%= rs.getString("author") %></td>
                                        <td><%= total %></td>
                                        <td><%= available %></td>
                                        <td><%= borrowed %></td>
                                    </tr>
                <%
                                }
                                rs.close();
                                pstmt.close();
                %>
                                    </tbody>
                                </table>
                <%
                            }
                        } catch (Exception e) {
                            out.println("<div class='alert alert-error'>Error generating report: " + e.getMessage() + "</div>");
                            e.printStackTrace();
                        } finally {
                            if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
                        }
                    } else {
                        // Show report options when no report is selected
                        out.println("<p>Select a report type to generate.</p>");
                    }
                %>
            </div>
        </div>
    </div>

    <script src="../js/app.js"></script>
    <script>
        function printReport() {
            // Hide form elements for printing
            document.querySelectorAll('form').forEach(form => form.style.display = 'none');
            document.querySelectorAll('.card-header').forEach(header => header.style.display = 'none');
            
            // Print the report content
            window.print();
            
            // Restore visibility after printing
            setTimeout(() => {
                document.querySelectorAll('form').forEach(form => form.style.display = '');
                document.querySelectorAll('.card-header').forEach(header => header.style.display = '');
            }, 1000);
        }
    </script>
    <%@ include file="../includes/footer.jsp" %>
</body>
</html>