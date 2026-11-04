<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, java.text.SimpleDateFormat, java.util.Date" %>
<%@ include file="../includes/header.jsp" %>
<%
    // Allow admin and librarian access
     if (!"admin".equals(session.getAttribute("role")) && !"librarian".equals(session.getAttribute("role"))) {
        response.sendRedirect("../auth/login.jsp");
        return;
    }
    
    // Handle loan approval/rejection
    String requestId = request.getParameter("request_id");
    String action = request.getParameter("action");
    String dueDate = request.getParameter("due_date");
    
    if (requestId != null && action != null) {
        Connection conn = null;
        try {
            Class.forName("oracle.jdbc.OracleDriver");
            String url = "jdbc:oracle:thin:@localhost:1521:xe";
            conn = DriverManager.getConnection(url, "c##library", "1234");
            
            conn.setAutoCommit(false);
            
            if ("approve".equals(action)) {
                // Get request details
                PreparedStatement pstmt = conn.prepareStatement(
                    "SELECT lr.user_id, lr.book_id, u.username, b.title, b.available_copies " +
                    "FROM c##library.loan_requests lr " +
                    "JOIN c##library.users u ON lr.user_id = u.user_id " +
                    "JOIN c##library.books b ON lr.book_id = b.book_id " +
                    "WHERE lr.request_id = ? AND lr.status = 'pending'"
                );
                pstmt.setInt(1, Integer.parseInt(requestId));
                ResultSet rs = pstmt.executeQuery();
                
                if (rs.next() && rs.getInt("available_copies") > 0) {
                    int userId = rs.getInt("user_id");
                    int bookId = rs.getInt("book_id");
                    
                    // Update loan request status
                    pstmt = conn.prepareStatement(
                        "UPDATE c##library.loan_requests SET status = 'approved', approved_by = ?, approved_date = SYSDATE, due_date = ? WHERE request_id = ?"
                    );
                    pstmt.setInt(1, (Integer) session.getAttribute("userId"));
                    pstmt.setDate(2, java.sql.Date.valueOf(dueDate));
                    pstmt.setInt(3, Integer.parseInt(requestId));
                    pstmt.executeUpdate();
                    
                    // Insert into issues table (actual loan)
                    pstmt = conn.prepareStatement(
                        "INSERT INTO c##library.issues (user_id, book_id, issue_date, due_date, status) VALUES (?, ?, SYSDATE, ?, 'active')"
                    );
                    pstmt.setInt(1, userId);
                    pstmt.setInt(2, bookId);
                    pstmt.setDate(3, java.sql.Date.valueOf(dueDate));
                    pstmt.executeUpdate();
                    
                    // Decrease available copies
                    pstmt = conn.prepareStatement(
                        "UPDATE c##library.books SET available_copies = available_copies - 1 WHERE book_id = ?"
                    );
                    pstmt.setInt(1, bookId);
                    pstmt.executeUpdate();
                    
                    conn.commit();
                    response.sendRedirect("approve_loans.jsp?message=Loan approved successfully&status=success");
                    return;
                } else {
                    response.sendRedirect("approve_loans.jsp?message=Book not available or request not found&status=error");
                    return;
                }
            }
            else if ("reject".equals(action)) {
                // Update request status to rejected
                PreparedStatement pstmt = conn.prepareStatement(
                    "UPDATE c##library.loan_requests SET status = 'rejected', approved_by = ?, approved_date = SYSDATE WHERE request_id = ?"
                );
                pstmt.setInt(1, (Integer) session.getAttribute("userId"));
                pstmt.setInt(2, Integer.parseInt(requestId));
                pstmt.executeUpdate();
                
                conn.commit();
                response.sendRedirect("approve_loans.jsp?message=Loan request rejected&status=success");
                return;
            }
            
           
        } catch (Exception e) {
            try { conn.rollback(); } catch (SQLException rollbackEx) {}
            response.sendRedirect("approve_loans.jsp?message=Error processing request&status=error");
        } finally {
            conn.setAutoCommit(true);
            if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Approve Loans - OpenLibrary</title>
    <link rel="stylesheet" href="../css/style.css">
</head>
<body>
    <div class="container">
        <div class="card">
            <div class="card-header">
                <h2 class="card-title">📋 Loan Requests</h2>
            </div>
            
            <!-- Message Display -->
            <% if (request.getParameter("message") != null) { %>
                <div class="alert alert-<%= request.getParameter("status") != null ? request.getParameter("status") : "info" %>">
                    <%= request.getParameter("message") %>
                </div>
            <% } %>
            
            <!-- Pending Requests Table -->
            <div class="card">
                <div class="card-header">
                    <h3 class="card-title">Pending Loan Requests</h3>
                </div>
                <table class="table">
                    <thead>
                        <tr>
                            <th>Request ID</th>
                            <th>Student</th>
                            <th>Book Title</th>
                            <th>Author</th>
                            <th>Request Date</th>
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
                                    "SELECT lr.request_id, u.username, b.title, b.author, lr.request_date " +
                                    "FROM c##library.loan_requests lr " +
                                    "JOIN c##library.users u ON lr.user_id = u.user_id " +
                                    "JOIN c##library.books b ON lr.book_id = b.book_id " +
                                    "WHERE lr.status = 'pending' " +
                                    "ORDER BY lr.request_date DESC"
                                );
                                ResultSet rs = pstmt.executeQuery();
                                
                                while (rs.next()) {
                        %>
                                    <tr>
                                        <td><%= rs.getInt("request_id") %></td>
                                        <td><%= rs.getString("username") %></td>
                                        <td><%= rs.getString("title") %></td>
                                        <td><%= rs.getString("author") %></td>
                                        <td><%= rs.getDate("request_date") %></td>
                                        <td>
                                            <!-- Approve form with due date input -->
                                            <form method="post" style="display:inline; margin-right: 0.5rem;">
                                                <input type="hidden" name="request_id" value="<%= rs.getInt("request_id") %>">
                                                <input type="hidden" name="action" value="approve">
                                                <input type="date" name="due_date" required style="width: 120px; margin-right: 0.5rem;">
                                                <button type="submit" class="btn btn-sm btn-primary">Approve</button>
                                            </form>
                                            <form method="post" style="display:inline;">
                                                <input type="hidden" name="request_id" value="<%= rs.getInt("request_id") %>">
                                                <input type="hidden" name="action" value="reject">
                                                <button type="submit" class="btn btn-sm btn-danger" 
                                                        onclick="return confirm('Reject this loan request?')">Reject</button>
                                            </form>
                                        </td>
                                    </tr>
                        <%
                                }
                                rs.close();
                                pstmt.close();
                            } catch (Exception e) {
                                out.println("<tr><td colspan='6' style='color:red;'>Error loading requests: " + e.getMessage() + "</td></tr>");
                            } finally {
                                if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
                            }
                        %>
                    </tbody>
                </table>
            </div>
            
            <!-- Approved Requests -->
<div class="card">
    <div class="card-header">
        <h3 class="card-title">Recent Approved Loans</h3>
    </div>
    <table class="table">
        <thead>
            <tr>
                <th>Request ID</th>
                <th>Student</th>
                <th>Book Title</th>
                <th>Approved By</th>
                <th>Approved Date</th>
                <th>Due Date</th>
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
                        "SELECT lr.request_id, u.username, b.title, u2.username as approved_by_name, lr.approved_date, lr.due_date " +
                        "FROM c##library.loan_requests lr " +
                        "JOIN c##library.users u ON lr.user_id = u.user_id " +
                        "JOIN c##library.books b ON lr.book_id = b.book_id " +
                        "JOIN c##library.users u2 ON lr.approved_by = u2.user_id " +
                        "WHERE lr.status = 'approved' " +
                        "ORDER BY lr.approved_date DESC" +
                        ") WHERE ROWNUM <= 10"
                    );
                    ResultSet rs = pstmt.executeQuery();
                    
                    while (rs.next()) {
            %>
                        <tr>
                            <td><%= rs.getInt("request_id") %></td>
                            <td><%= rs.getString("username") %></td>
                            <td><%= rs.getString("title") %></td>
                            <td><%= rs.getString("approved_by_name") %></td>
                            <td><%= rs.getDate("approved_date") %></td>
                            <td><%= rs.getDate("due_date") %></td>
                        </tr>
            <%
                    }
                    rs.close();
                    pstmt.close();
                } catch (Exception e) {
                    out.println("<tr><td colspan='6' style='color:red;'>Error loading approved loans: " + e.getMessage() + "</td></tr>");
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
            const inputs = document.querySelectorAll('input[name="due_date"]');
            inputs.forEach(input => {
                if (!input.value) {
                    const today = new Date();
                    const dueDate = new Date(today);
                    dueDate.setDate(dueDate.getDate() + 14); // 14 days default
                    const formattedDate = dueDate.toISOString().split('T')[0];
                    input.value = formattedDate;
                }
            });
        });
    </script>
    <%@ include file="../includes/footer.jsp" %>
</body>
</html>