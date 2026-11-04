<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, java.io.*, java.text.SimpleDateFormat, java.util.Date, java.time.LocalDate, java.time.temporal.ChronoUnit" %>
<%@ include file="../includes/header.jsp" %>
<%
    // Verify admin access
    if (!"admin".equals(session.getAttribute("role"))) {
        response.sendRedirect("auth/login.jsp");
        return;
    }
    
    String action = request.getParameter("action");
    String message = "";
    String messageType = "info";
    
    if ("backup".equals(action)) {
        try {
            // Create backup file in a download directory
            String backupDir = getServletContext().getRealPath("/backups");
            File dir = new File(backupDir);
            if (!dir.exists()) {
                dir.mkdirs(); // Create backups directory if it doesn't exist
            }
            
            // Generate filename with timestamp
            SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMdd_HHmmss");
            String timestamp = sdf.format(new Date());
            String filename = "openlibrary_backup_" + timestamp + ".sql";
            String filepath = backupDir + File.separator + filename;
            
            // Create the backup file
            PrintWriter writer = new PrintWriter(filepath, "UTF-8");
            
            // Write backup header
            writer.println("-- OpenLibrary Database Backup");
            writer.println("-- Generated on: " + new Date());
            writer.println("--");
            
            // Get connection to database
            Class.forName("oracle.jdbc.OracleDriver");
            String url = "jdbc:oracle:thin:@localhost:1521:xe";
            Connection conn = DriverManager.getConnection(url, "c##library", "1234");
            
            // Backup users table
            writer.println("-- Table: users");
            writer.println("DELETE FROM c##library.users;");
            PreparedStatement pstmt = conn.prepareStatement("SELECT * FROM c##library.users");
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                writer.println("INSERT INTO c##library.users (user_id, username, password_hash, role, name, email, created_at, updated_at) VALUES (" +
                    rs.getInt("user_id") + ", '" +
                    rs.getString("username").replace("'", "''") + "', '" +
                    rs.getString("password_hash").replace("'", "''") + "', '" +
                    rs.getString("role") + "', '" +
                    rs.getString("name").replace("'", "''") + "', '" +
                    rs.getString("email") + "', '" +
                    rs.getTimestamp("created_at") + "', '" +
                    rs.getTimestamp("updated_at") + "');");
            }
            rs.close();
            pstmt.close();
            
            // Backup books table
            writer.println("\n-- Table: books");
            writer.println("DELETE FROM c##library.books;");
            pstmt = conn.prepareStatement("SELECT * FROM c##library.books");
            rs = pstmt.executeQuery();
            
            while (rs.next()) {
                writer.println("INSERT INTO c##library.books (book_id, title, author, isbn, total_copies, available_copies, category, description, added_date) VALUES (" +
                    rs.getInt("book_id") + ", '" +
                    rs.getString("title").replace("'", "''") + "', '" +
                    rs.getString("author").replace("'", "''") + "', '" +
                    rs.getString("isbn") + "', " +
                    rs.getInt("total_copies") + ", " +
                    rs.getInt("available_copies") + ", '" +
                    rs.getString("category") + "', '" +
                    (rs.getString("description") != null ? rs.getString("description").replace("'", "''") : "") + "', '" +
                    rs.getDate("added_date") + "');");
            }
            rs.close();
            pstmt.close();
            
            // Backup issues table
            writer.println("\n-- Table: issues");
            writer.println("DELETE FROM c##library.issues;");
            pstmt = conn.prepareStatement("SELECT * FROM c##library.issues");
            rs = pstmt.executeQuery();
            
            while (rs.next()) {
                writer.println("INSERT INTO c##library.issues (issue_id, user_id, book_id, issue_date, due_date, return_date, status) VALUES (" +
                    rs.getInt("issue_id") + ", " +
                    rs.getInt("user_id") + ", " +
                    rs.getInt("book_id") + ", '" +
                    rs.getDate("issue_date") + "', '" +
                    rs.getDate("due_date") + "', " +
                    (rs.getDate("return_date") != null ? "'" + rs.getDate("return_date") + "'" : "NULL") + ", '" +
                    rs.getString("status") + "');");
            }
            rs.close();
            pstmt.close();
            
            // Backup fines table
            writer.println("\n-- Table: fines");
            writer.println("DELETE FROM c##library.fines;");
            pstmt = conn.prepareStatement("SELECT * FROM c##library.fines");
            rs = pstmt.executeQuery();
            
            while (rs.next()) {
                writer.println("INSERT INTO c##library.fines (fine_id, issue_id, amount, fine_date, status, paid_date) VALUES (" +
                    rs.getInt("fine_id") + ", " +
                    rs.getInt("issue_id") + ", " +
                    rs.getDouble("amount") + ", '" +
                    rs.getDate("fine_date") + "', '" +
                    rs.getString("status") + "', " +
                    (rs.getDate("paid_date") != null ? "'" + rs.getDate("paid_date") + "'" : "NULL") + ");");
            }
            rs.close();
            pstmt.close();
            
            // Backup loan_requests table
            writer.println("\n-- Table: loan_requests");
            writer.println("DELETE FROM c##library.loan_requests;");
            pstmt = conn.prepareStatement("SELECT * FROM c##library.loan_requests");
            rs = pstmt.executeQuery();
            
            while (rs.next()) {
                writer.println("INSERT INTO c##library.loan_requests (request_id, user_id, book_id, request_date, status, approved_by, approved_date, due_date, notes) VALUES (" +
                    rs.getInt("request_id") + ", " +
                    rs.getInt("user_id") + ", " +
                    rs.getInt("book_id") + ", '" +
                    rs.getDate("request_date") + "', '" +
                    rs.getString("status") + "', " +
                    (rs.getInt("approved_by") != 0 ? String.valueOf(rs.getInt("approved_by")) : "NULL") + ", " +
                    (rs.getDate("approved_date") != null ? "'" + rs.getDate("approved_date") + "'" : "NULL") + ", " +
                    (rs.getDate("due_date") != null ? "'" + rs.getDate("due_date") + "'" : "NULL") + ", '" +
                    (rs.getString("notes") != null ? rs.getString("notes").replace("'", "''") : "") + "');");
            }
            rs.close();
            pstmt.close();
            
            writer.close();
            conn.close();
            
            // Trigger download of the backup file
            response.setContentType("application/sql");
            response.setContentLength((int) new File(filepath).length());
            response.setHeader("Content-Disposition", "attachment; filename=\"" + filename + "\"");
            
            FileInputStream fis = new FileInputStream(filepath);
            OutputStream os = response.getOutputStream();
            byte[] buffer = new byte[4096];
            int bytesRead;
            while ((bytesRead = fis.read(buffer)) != -1) {
                os.write(buffer, 0, bytesRead);
            }
            os.flush();
            os.close();
            fis.close();
            
            // Don't continue with page rendering since we're sending file
            return;
            
        } catch (Exception e) {
            message = "Error creating backup: " + e.getMessage();
            messageType = "error";
        }
    }
    else if ("cleanup".equals(action)) {
        try {
            // Perform system cleanup tasks
            Connection conn = null;
            try {
                Class.forName("oracle.jdbc.OracleDriver");
                String url = "jdbc:oracle:thin:@localhost:1521:xe";
                conn = DriverManager.getConnection(url, "c##library", "1234");
                
                // Clean up old loan requests (older than 30 days)
                PreparedStatement pstmt = conn.prepareStatement(
                    "DELETE FROM c##library.loan_requests WHERE request_date < SYSDATE - 30 AND status = 'pending'"
                );
                int oldRequestsDeleted = pstmt.executeUpdate();
                pstmt.close();
                
                // Clean up old fines (older than 1 year, paid fines)
                pstmt = conn.prepareStatement(
                    "DELETE FROM c##library.fines WHERE fine_date < SYSDATE - 365 AND status = 'paid'"
                );
                int oldFinesDeleted = pstmt.executeUpdate();
                pstmt.close();
                
                // Clean up old sessions (if you had a sessions table)
                // Clean up temp files in uploads directory
                String uploadDir = getServletContext().getRealPath("/uploads");
                if (uploadDir != null) {
                    File uploadDirectory = new File(uploadDir);
                    if (uploadDirectory.exists()) {
                        File[] files = uploadDirectory.listFiles();
                        if (files != null) {
                            for (File file : files) {
                                if (file.getName().startsWith("temp_") && 
                                    System.currentTimeMillis() - file.lastModified() > 86400000) { // older than 24 hours
                                    file.delete();
                                }
                            }
                        }
                    }
                }
                
                message = "System cleanup completed successfully!<br>" +
                          "- Deleted " + oldRequestsDeleted + " old pending loan requests<br>" +
                          "- Deleted " + oldFinesDeleted + " old paid fines<br>" +
                          "- Cleaned up temporary files";
                messageType = "success";
                
            } finally {
                if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
            }
        } catch (Exception e) {
            message = "Error during cleanup: " + e.getMessage();
            messageType = "error";
        }
    }
    else if ("optimize".equals(action)) {
        try {
            Connection conn = null;
            try {
                Class.forName("oracle.jdbc.OracleDriver");
                String url = "jdbc:oracle:thin:@localhost:1521:xe";
                conn = DriverManager.getConnection(url, "c##library", "1234");
                
                // Optimize database tables (Oracle-specific commands)
                Statement stmt = conn.createStatement();
                
                // Analyze tables for better query performance
                stmt.executeUpdate("ANALYZE TABLE c##library.users COMPUTE STATISTICS");
                stmt.executeUpdate("ANALYZE TABLE c##library.books COMPUTE STATISTICS");
                stmt.executeUpdate("ANALYZE TABLE c##library.issues COMPUTE STATISTICS");
                stmt.executeUpdate("ANALYZE TABLE c##library.fines COMPUTE STATISTICS");
                stmt.executeUpdate("ANALYZE TABLE c##library.loan_requests COMPUTE STATISTICS");
                
                stmt.close();
                
                message = "Database optimization completed successfully!<br>" +
                          "- Updated statistics for all tables<br>" +
                          "- Optimized query execution plans<br>" +
                          "- Improved overall database performance";
                messageType = "success";
                
            } finally {
                if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
            }
        } catch (Exception e) {
            message = "Error during optimization: " + e.getMessage();
            messageType = "error";
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>System Maintenance - OpenLibrary</title>
    <link rel="stylesheet" href="../css/style.css">
</head>
<body>
    <div class="container">
        <div class="card">
            <div class="card-header">
                <h2 class="card-title">🔧 System Maintenance</h2>
            </div>
            
            <% if (!message.isEmpty()) { %>
                <div class="alert alert-<%= messageType %>">
                    <%= message %>
                </div>
            <% } %>
            
            <div class="card">
                <h3>Database Backup</h3>
                <p>Create a backup of the entire database for safekeeping.</p>
                <form method="post" action="system_maintenance.jsp">
                    <input type="hidden" name="action" value="backup">
                    <button type="submit" class="btn btn-primary" onclick="return confirm('Create database backup?')">Create Backup</button>
                </form>
            </div>
            
            <div class="card">
                <h3>System Cleanup</h3>
                <p>Clean up old records and temporary files to improve performance.</p>
                <form method="post" action="system_maintenance.jsp">
                    <input type="hidden" name="action" value="cleanup">
                    <button type="submit" class="btn btn-warning" onclick="return confirm('Perform system cleanup?')">Cleanup</button>
                </form>
            </div>
            
            <div class="card">
                <h3>Database Optimization</h3>
                <p>Optimize database tables and update statistics for better performance.</p>
                <form method="post" action="system_maintenance.jsp">
                    <input type="hidden" name="action" value="optimize">
                    <button type="submit" class="btn btn-success" onclick="return confirm('Optimize database?')">Optimize</button>
                </form>
            </div>
        </div>
    </div>

    <script src="../js/app.js"></script>
    <%@ include file="../includes/footer.jsp" %>
</body>
</html>