<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, java.text.SimpleDateFormat" %>
<%@ include file="../includes/header.jsp" %>
<%
    // Allow admin and librarian access
    if (!"admin".equals(session.getAttribute("role")) && !"librarian".equals(session.getAttribute("role"))) {
        response.sendRedirect("../auth/login.jsp");
        return;
    }
    
    String message = request.getParameter("message");
    String messageType = request.getParameter("type");
    
    // Handle form submission (both create and update)
    String action = request.getParameter("action");
    if ("create".equals(action)) {
        String title = request.getParameter("title");
        String author = request.getParameter("author");
        String isbn = request.getParameter("isbn");
        String totalCopiesStr = request.getParameter("total_copies");
        String category = request.getParameter("category");
        String description = request.getParameter("description");

        Connection conn = null;
        try {
            Class.forName("oracle.jdbc.OracleDriver");
            String url = "jdbc:oracle:thin:@localhost:1521:xe";
            conn = DriverManager.getConnection(url, "c##library", "1234");

            int totalCopies = Integer.parseInt(totalCopiesStr);
            int availableCopies = totalCopies; // For new books, available = total

            PreparedStatement pstmt = conn.prepareStatement(
                "INSERT INTO c##library.books (title, author, isbn, total_copies, available_copies, category, description) VALUES (?, ?, ?, ?, ?, ?, ?)"
            );
            pstmt.setString(1, title);
            pstmt.setString(2, author);
            pstmt.setString(3, isbn);
            pstmt.setInt(4, totalCopies);
            pstmt.setInt(5, availableCopies);
            pstmt.setString(6, category);
            pstmt.setString(7, description);
            
            pstmt.executeUpdate();
            pstmt.close();
            
            response.sendRedirect("manage_books.jsp?message=Book added successfully&status=success");
            return;
        } catch (Exception e) {
            response.sendRedirect("manage_books.jsp?message=Error adding book: " + e.getMessage() + "&status=error");
            return;
        } finally {
            if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
        }
    }
    else if ("update".equals(action)) {
        String bookIdStr = request.getParameter("book_id");
        String title = request.getParameter("title");
        String author = request.getParameter("author");
        String isbn = request.getParameter("isbn");
        String totalCopiesStr = request.getParameter("total_copies");
        String category = request.getParameter("category");
        String description = request.getParameter("description");

        Connection conn = null;
        try {
            Class.forName("oracle.jdbc.OracleDriver");
            String url = "jdbc:oracle:thin:@localhost:1521:xe";
            conn = DriverManager.getConnection(url, "c##library", "1234");

            int bookId = Integer.parseInt(bookIdStr);
            int totalCopies = Integer.parseInt(totalCopiesStr);
            
            // Calculate available copies (this is more complex in real systems)
            // For now, if total copies increased, add to available; if decreased, ensure available doesn't exceed total
            PreparedStatement checkPstmt = conn.prepareStatement(
                "SELECT available_copies FROM c##library.books WHERE book_id = ?"
            );
            checkPstmt.setInt(1, bookId);
            ResultSet rs = checkPstmt.executeQuery();
            int currentAvailable = 0;
            if (rs.next()) {
                currentAvailable = rs.getInt("available_copies");
            }
            rs.close();
            checkPstmt.close();
            
            // Adjust available copies based on total change
            int newAvailable = currentAvailable;
            if (totalCopies > currentAvailable) {
                newAvailable = totalCopies; // If increasing total, make available equal to total
            } else if (totalCopies < currentAvailable) {
                newAvailable = totalCopies; // If decreasing total, cap available
            }
            
            PreparedStatement pstmt = conn.prepareStatement(
                "UPDATE c##library.books SET title=?, author=?, isbn=?, total_copies=?, available_copies=?, category=?, description=? WHERE book_id=?"
            );
            pstmt.setString(1, title);
            pstmt.setString(2, author);
            pstmt.setString(3, isbn);
            pstmt.setInt(4, totalCopies);
            pstmt.setInt(5, newAvailable);
            pstmt.setString(6, category);
            pstmt.setString(7, description);
            pstmt.setInt(8, bookId);
            
            pstmt.executeUpdate();
            pstmt.close();
            
            response.sendRedirect("manage_books.jsp?message=Book updated successfully&status=success");
            return;
        } catch (Exception e) {
            response.sendRedirect("manage_books.jsp?message=Error updating book: " + e.getMessage() + "&status=error");
            return;
        } finally {
            if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manage Books - OpenLibrary</title>
    <link rel="stylesheet" href="../css/style.css">
</head>
<body>
    <div class="container">
        <div class="card">
            <div class="card-header">
                <h2 class="card-title">📚 Manage Books</h2>
                <button onclick="showAddBookForm()" class="btn btn-primary">Add Book</button>
            </div>
            
            <!-- Message Display -->
            <% if (message != null) { %>
                <div class="alert alert-<%= messageType != null ? messageType : "info" %>">
                    <%= message %>
                </div>
            <% } %>
            
            <!-- Add/Edit Book Modal -->
            <div id="bookModal" class="modal" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(0,0,0,0.5); z-index:1000;">
                <div style="background:white; margin:5% auto; padding:2rem; width:90%; max-width:600px; border-radius:8px;">
                    <h3 id="bookModalTitle">Add New Book</h3>
                    <form id="bookForm" method="post" action="manage_books.jsp">
                        <input type="hidden" id="bookAction" name="action" value="create">
                        <input type="hidden" id="editBookId" name="book_id">
                        
                        <div class="form-group">
                            <label>Title *</label>
                            <input type="text" id="title" name="title" required>
                        </div>
                        
                        <div class="form-group">
                            <label>Author *</label>
                            <input type="text" id="author" name="author" required>
                        </div>
                        
                        <div class="form-group">
                            <label>ISBN</label>
                            <input type="text" id="isbn" name="isbn">
                        </div>
                        
                        <div class="form-group">
                            <label>Total Copies *</label>
                            <input type="number" id="totalCopies" name="total_copies" min="1" value="1" required>
                        </div>
                        
                        <div class="form-group">
                            <label>Category</label>
                            <input type="text" id="category" name="category">
                        </div>
                        
                        <div class="form-group">
                            <label>Description</label>
                            <textarea id="description" name="description" rows="3"></textarea>
                        </div>
                        
                        <div style="margin-top:1rem; display:flex; gap:1rem;">
                            <button type="submit" class="btn btn-primary">Save</button>
                            <button type="button" onclick="closeModal()" class="btn btn-danger">Cancel</button>
                        </div>
                    </form>
                </div>
            </div>
            
            <!-- Search Books -->
            <div class="form-group">
                <input type="text" id="searchInput" placeholder="Search books (title, author, category)..." data-search="#booksTable">
            </div>
            
            <!-- Books Table -->
            <table class="table" id="booksTable">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Title</th>
                        <th>Author</th>
                        <th>ISBN</th>
                        <th>Total</th>
                        <th>Available</th>
                        <th>Category</th>
                        <th>Added Date</th>
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
                            
                            // Load ALL books without any limits
                            PreparedStatement pstmt = conn.prepareStatement(
                                "SELECT book_id, title, author, isbn, total_copies, available_copies, category, added_date, description FROM c##library.books ORDER BY book_id DESC"
                            );
                            ResultSet rs = pstmt.executeQuery();
                            
                            int bookCount = 0;
                            while (rs.next()) {
                                bookCount++;
                    %>
                                <tr>
                                    <td><%= rs.getInt("book_id") %></td>
                                    <td><%= rs.getString("title") %></td>
                                    <td><%= rs.getString("author") %></td>
                                    <td><%= rs.getString("isbn") %></td>
                                    <td><%= rs.getInt("total_copies") %></td>
                                    <td><%= rs.getInt("available_copies") %></td>
                                    <td><%= rs.getString("category") %></td>
                                    <td><%= rs.getDate("added_date") %></td>
                                    <td>
                                        <button onclick="editBook(<%= rs.getInt("book_id") %>, '<%= rs.getString("title").replace("'", "\\'") %>', '<%= rs.getString("author").replace("'", "\\'") %>', '<%= rs.getString("isbn").replace("'", "\\'") %>', <%= rs.getInt("total_copies") %>, '<%= rs.getString("category").replace("'", "\\'") %>', '<%= rs.getString("description") != null ? rs.getString("description").replace("'", "\\'") : "" %>')" class="btn btn-sm btn-primary">Edit</button>
                                        <button onclick="deleteBook(<%= rs.getInt("book_id") %>)" class="btn btn-sm btn-danger" data-confirm="Are you sure you want to delete this book?">Delete</button>
                                    </td>
                                </tr>
                    <%
                            }
                            
                            // Show summary if no books
                            if (bookCount == 0) {
                    %>
                                <tr>
                                    <td colspan="9" style="text-align:center; color:red; font-weight:bold;">
                                        No books found in database
                                    </td>
                                </tr>
                    <%
                            }
                            
                            rs.close();
                            pstmt.close();
                        } catch (Exception e) {
                            out.println("<tr><td colspan='9' style='color:red; font-weight:bold; text-align:center;'>ERROR: " + e.getMessage() + "</td></tr>");
                            e.printStackTrace(new java.io.PrintWriter(out));
                        } finally {
                            if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
                        }
                    %>
                </tbody>
            </table>
        </div>
    </div>

    <script src="../js/app.js"></script>
    <script>
        function showAddBookForm() {
            document.getElementById('bookModalTitle').textContent = 'Add New Book';
            document.getElementById('bookAction').value = 'create';
            document.getElementById('bookForm').reset();
            document.getElementById('totalCopies').value = '1';
            document.getElementById('editBookId').value = '';
            document.getElementById('bookModal').style.display = 'block';
        }

        function editBook(id, title, author, isbn, totalCopies, category, description) {
            document.getElementById('bookModalTitle').textContent = 'Edit Book';
            document.getElementById('bookAction').value = 'update';
            document.getElementById('editBookId').value = id;
            document.getElementById('title').value = title;
            document.getElementById('author').value = author;
            document.getElementById('isbn').value = isbn || '';
            document.getElementById('totalCopies').value = totalCopies;
            document.getElementById('category').value = category || '';
            document.getElementById('description').value = description || '';
            document.getElementById('bookModal').style.display = 'block';
        }

        function closeModal() {
            document.getElementById('bookModal').style.display = 'none';
        }

        function deleteBook(bookId) {
            if (confirm('Are you sure you want to delete this book?')) {
                const form = document.createElement('form');
                form.method = 'post';
                form.action = 'manage_books_process.jsp';
                form.style.display = 'none';
                
                const actionInput = document.createElement('input');
                actionInput.type = 'hidden';
                actionInput.name = 'action';
                actionInput.value = 'delete';
                
                const bookIdInput = document.createElement('input');
                bookIdInput.type = 'hidden';
                bookIdInput.name = 'book_id';
                bookIdInput.value = bookId;
                
                form.appendChild(actionInput);
                form.appendChild(bookIdInput);
                document.body.appendChild(form);
                form.submit();
            }
        }
        
        // Search functionality
        document.addEventListener('DOMContentLoaded', function() {
            const searchInput = document.getElementById('searchInput');
            const table = document.getElementById('booksTable');
            
            if (searchInput && table) {
                searchInput.addEventListener('keyup', function() {
                    const searchTerm = this.value.toLowerCase();
                    const rows = table.getElementsByTagName('tbody')[0].getElementsByTagName('tr');
                    
                    for (let i = 0; i < rows.length; i++) {
                        const row = rows[i];
                        const cells = row.getElementsByTagName('td');
                        
                        let found = false;
                        for (let j = 1; j < cells.length - 1; j++) { // Skip ID and Actions columns
                            if (cells[j].textContent.toLowerCase().includes(searchTerm)) {
                                found = true;
                                break;
                            }
                        }
                        
                        row.style.display = found ? '' : 'none';
                    }
                });
            }
        });
    </script>
    <%@ include file="../includes/footer.jsp" %>
</body>
</html>