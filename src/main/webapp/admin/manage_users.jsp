<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ include file="../includes/header.jsp" %>
<%
    // Verify admin access
    if (!"admin".equals(session.getAttribute("role"))) {
        response.sendRedirect("../auth/login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manage Users - OpenLibrary</title>
    <link rel="stylesheet" href="../css/style.css">
</head>
<body>
    <div class="container">
        <div class="card">
            <div class="card-header">
                <h2 class="card-title">👥 Manage Users</h2>
                <button onclick="showAddUserForm()" class="btn btn-primary">Add User</button>
            </div>
            
            <!-- Add/Edit User Modal -->
            <div id="userModal" class="modal" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(0,0,0,0.5); z-index:1000;">
                <div style="background:white; margin:10% auto; padding:2rem; width:90%; max-width:500px; border-radius:8px;">
                    <h3 id="modalTitle">Add New User</h3>
                    <form id="userForm" method="post" action="manage_users_process.jsp">
                        <input type="hidden" id="action" name="action" value="create">
                        <input type="hidden" id="editUserId" name="user_id">
                        
                        <div class="form-group">
                            <label>Username *</label>
                            <input type="text" id="username" name="username" required>
                        </div>
                        
                        <div class="form-group">
                            <label>Name *</label>
                            <input type="text" id="name" name="name" required>
                        </div>
                        
                        <div class="form-group">
                            <label>Email</label>
                            <input type="email" id="email" name="email">
                        </div>
                        
                        <div class="form-group">
                            <label>Role *</label>
                            <select id="role" name="role" required>
                                <option value="student">Student</option>
                                <option value="librarian">Librarian</option>
                                <option value="admin">Admin</option>
                            </select>
                        </div>
                        
                        <div class="form-group">
                            <label>Password *</label>
                            <input type="password" id="password" name="password" required>
                        </div>
                        
                        <div style="margin-top:1rem; display:flex; gap:1rem;">
                            <button type="submit" class="btn btn-primary">Save</button>
                            <button type="button" onclick="closeModal()" class="btn btn-danger">Cancel</button>
                        </div>
                    </form>
                </div>
            </div>
            
            <!-- Search Users -->
            <div class="form-group">
                <input type="text" id="searchInput" placeholder="Search users..." data-search="#usersTable">
            </div>
            
            <!-- Users Table -->
            <table class="table" id="usersTable">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Username</th>
                        <th>Name</th>
                        <th>Email</th>
                        <th>Role</th>
                        <th>Created Date</th>
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
                                "SELECT user_id, username, name, email, role, created_at FROM c##library.users ORDER BY user_id DESC"
                            );
                            ResultSet rs = pstmt.executeQuery();
                            
                            while (rs.next()) {
                    %>
                                <tr>
                                    <td><%= rs.getInt("user_id") %></td>
                                    <td><%= rs.getString("username") %></td>
                                    <td><%= rs.getString("name") %></td>
                                    <td><%= rs.getString("email") %></td>
                                    <td><span style="background:<%= 
                                        rs.getString("role").equals("admin") ? "#fef3c7;" : 
                                        rs.getString("role").equals("librarian") ? "#dbeafe;" : "#dcfce7;" 
                                    %> padding:0.2rem 0.5rem; border-radius:4px; color:black;">
                                        <%= rs.getString("role") %>
                                    </span></td>
                                    <td><%= rs.getDate("created_at") %></td>
                                    <td>
                                        <button onclick="editUser(<%= rs.getInt("user_id") %>, '<%= rs.getString("username") %>', '<%= rs.getString("name") %>', '<%= rs.getString("email") %>', '<%= rs.getString("role") %>')" class="btn btn-sm btn-primary">Edit</button>
                                        <button onclick="deleteUser(<%= rs.getInt("user_id") %>)" class="btn btn-sm btn-danger" data-confirm="Are you sure you want to delete this user?">Delete</button>
                                    </td>
                                </tr>
                    <%
                            }
                            rs.close();
                            pstmt.close();
                        } catch (Exception e) {
                            out.println("<tr><td colspan='7' style='color:red;'>Error loading users: " + e.getMessage() + "</td></tr>");
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
        function showAddUserForm() {
            document.getElementById('modalTitle').textContent = 'Add New User';
            document.getElementById('action').value = 'create';
            document.getElementById('userForm').reset();
            document.getElementById('password').required = true;
            document.getElementById('userModal').style.display = 'block';
        }

        function editUser(id, username, name, email, role) {
            document.getElementById('modalTitle').textContent = 'Edit User';
            document.getElementById('action').value = 'update';
            document.getElementById('editUserId').value = id;
            document.getElementById('username').value = username;
            document.getElementById('name').value = name;
            document.getElementById('email').value = email || '';
            document.getElementById('role').value = role;
            document.getElementById('password').required = false; // Don't require password on edit
            document.getElementById('userModal').style.display = 'block';
        }

        function closeModal() {
            document.getElementById('userModal').style.display = 'none';
        }

        function deleteUser(userId) {
            if (confirm('Are you sure you want to delete this user?')) {
                // Create form to submit delete request
                const form = document.createElement('form');
                form.method = 'post';
                form.action = 'manage_users_process.jsp';
                form.style.display = 'none';
                
                const actionInput = document.createElement('input');
                actionInput.type = 'hidden';
                actionInput.name = 'action';
                actionInput.value = 'delete';
                
                const userIdInput = document.createElement('input');
                userIdInput.type = 'hidden';
                userIdInput.name = 'user_id';
                userIdInput.value = userId;
                
                form.appendChild(actionInput);
                form.appendChild(userIdInput);
                document.body.appendChild(form);
                form.submit();
            }
        }
    </script>
    <%@ include file="../includes/footer.jsp" %>
</body>
</html>