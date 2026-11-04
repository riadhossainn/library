<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="../includes/header.jsp" %>
<%
    // Allow all roles to access help
    if (session.getAttribute("userId") == null) {
        response.sendRedirect("../auth/login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>User Manual - OpenLibrary</title>
    <link rel="stylesheet" href="../css/style.css">
    <style>
        .manual-section {
            margin-bottom: 2rem;
            padding: 1rem;
            border-left: 4px solid var(--secondary);
            background: var(--bg);
        }
        .manual-subsection {
            margin: 1rem 0;
            padding: 0.5rem;
            background: white;
            border-radius: 4px;
        }
        .tip {
            background: #f0fdf4;
            border-left: 3px solid var(--success);
            padding: 0.5rem;
            margin: 0.5rem 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="card">
            <div class="card-header">
                <h2 class="card-title">📖 OpenLibrary User Manual</h2>
            </div>
            
            <div class="manual-section">
                <h3>📋 Table of Contents</h3>
                <ul>
                    <li><a href="#getting-started">Getting Started</a></li>
                    <li><a href="#admin-guide">Admin Guide</a></li>
                    <li><a href="#librarian-guide">Librarian Guide</a></li>
                    <li><a href="#student-guide">Student Guide</a></li>
                    <li><a href="#troubleshooting">Troubleshooting</a></li>
                </ul>
            </div>
            
            <div class="manual-section" id="getting-started">
                <h3>🚀 Getting Started</h3>
                <div class="manual-subsection">
                    <h4>Login Process</h4>
                    <p>1. Navigate to the login page</p>
                    <p>2. Enter your username and password</p>
                    <p>3. Click "Sign In"</p>
                    <p>4. You will be redirected to your role-specific dashboard</p>
                </div>
                <div class="manual-subsection">
                    <h4>Navigation</h4>
                    <p>The navigation bar at the top allows you to access different sections of the system based on your role.</p>
                    <div class="tip">💡 <strong>Tip:</strong> Always log out when finished using the system.</div>
                </div>
            </div>
            
            <div class="manual-section" id="admin-guide">
                <h3>👑 Admin Guide</h3>
                <div class="manual-subsection">
                    <h4>Manage Users</h4>
                    <p>Admins can add, edit, and delete users through the "Manage Users" section.</p>
                    <ul>
                        <li><strong>Add User:</strong> Click "Add User" button and fill in the form</li>
                        <li><strong>Edit User:</strong> Click "Edit" button next to user</li>
                        <li><strong>Delete User:</strong> Click "Delete" button (confirmation required)</li>
                    </ul>
                </div>
                <div class="manual-subsection">
                    <h4>Generate Reports</h4>
                    <p>Access comprehensive reports about system usage, loans, fines, and inventory.</p>
                </div>
            </div>
            
            <div class="manual-section" id="librarian-guide">
                <h3>📚 Librarian Guide</h3>
                <div class="manual-subsection">
                    <h4>Manage Books</h4>
                    <p>Librarians can manage the library's book inventory.</p>
                    <ul>
                        <li><strong>Add Book:</strong> Click "Add Book" and enter book details</li>
                        <li><strong>Edit Book:</strong> Click "Edit" next to existing book</li>
                        <li><strong>Delete Book:</strong> Click "Delete" (only if no active loans)</li>
                    </ul>
                </div>
                <div class="manual-subsection">
                    <h4>Process Loans</h4>
                    <p>Issue books to students and process returns.</p>
                    <ol>
                        <li>Enter student username and book ID</li>
                        <li>Set due date (default is 14 days)</li>
                        <li>Click "Issue Book"</li>
                    </ol>
                </div>
            </div>
            
            <div class="manual-section" id="student-guide">
                <h3>🎓 Student Guide</h3>
                <div class="manual-subsection">
                    <h4>Browse Books</h4>
                    <p>Students can search and browse available books.</p>
                    <ul>
                        <li>Use the search bar to find specific books</li>
                        <li>Filter by category if needed</li>
                        <li>Check availability before requesting</li>
                    </ul>
                </div>
                <div class="manual-subsection">
                    <h4>My Loans</h4>
                    <p>Track your current loans and due dates.</p>
                    <p>You can have up to 5 books checked out at once.</p>
                    <div class="tip">⚠️ <strong>Warning:</strong> Books are overdue if returned after the due date. Fines apply.</div>
                </div>
            </div>
            
            <div class="manual-section" id="troubleshooting">
                <h3>❓ Troubleshooting</h3>
                <div class="manual-subsection">
                    <h4>Login Issues</h4>
                    <p>If you cannot login:</p>
                    <ul>
                        <li>Check your username and password spelling</li>
                        <li>Ensure Caps Lock is off</li>
                        <li>Contact admin if account is locked</li>
                    </ul>
                </div>
                <div class="manual-subsection">
                    <h4>General Tips</h4>
                    <ul>
                        <li>Always refresh the page if data seems outdated</li>
                        <li>Clear browser cache if experiencing issues</li>
                        <li>Contact support for persistent problems</li>
                    </ul>
                </div>
            </div>
        </div>
    </div>

    <script src="../js/app.js"></script>
    <%@ include file="../includes/footer.jsp" %>
</body>
</html>