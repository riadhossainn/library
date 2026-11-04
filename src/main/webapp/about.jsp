<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="includes/header.jsp" %>
<%
    // Allow all roles to access about page
    if (session.getAttribute("userId") == null) {
        response.sendRedirect("auth/login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>About - OpenLibrary</title>
    <link rel="stylesheet" href="css/style.css">
    <style>
        .about-card {
            text-align: center;
            padding: 2rem;
        }
        .features-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 1rem;
            margin: 2rem 0;
        }
        .feature-card {
            background: var(--bg);
            padding: 1.5rem;
            border-radius: 8px;
            text-align: center;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="card about-card">
            <h2>📘 OpenLibrary</h2>
            <p style="font-size: 1.2rem; color: var(--text-light); margin: 1rem 0;">Library Management System</p>
            <p>A comprehensive library management solution built with Java, Oracle, and pure JSP technology.</p>
        </div>
        
        <div class="card">
            <div class="card-header">
                <h3 class="card-title">✨ Key Features</h3>
            </div>
            <div class="features-grid">
                <div class="feature-card">
                    <h4>📚 Book Management</h4>
                    <p>Complete inventory control with add, edit, and delete functionality</p>
                </div>
                <div class="feature-card">
                    <h4>👥 User Management</h3>
                    <p>Three-tier role system: Admin, Librarian, and Student</p>
                </div>
                <div class="feature-card">
                    <h4>💰 Fine Calculation</h4>
                    <p>Automatic fine calculation for overdue books (₹2 per day)</p>
                </div>
                <div class="feature-card">
                    <h4>📊 Reporting</h4>
                    <p>Comprehensive reports for library administration</p>
                </div>
                <div class="feature-card">
                    <h4>🔒 Security</h4>
                    <p>Secure authentication and role-based access control</p>
                </div>
                <div class="feature-card">
                    <h4>⚡ Performance</h4>
                    <p>Optimized for fast queries and smooth operation</p>
                </div>
            </div>
        </div>
        
        <div class="card">
            <div class="card-header">
                <h3 class="card-title">🛠️ Technical Details</h3>
            </div>
            <div class="grid" style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 2rem;">
                <div>
                    <h4>Backend</h4>
                    <ul style="list-style: none; padding: 0;">
                        <li>• Java 21</li>
                        <li>• Oracle 21c</li>
                        <li>• Pure JSP (no frameworks)</li>
                        <li>• JDBC for database access</li>
                    </ul>
                </div>
                <div>
                    <h4>Frontend</h4>
                    <ul style="list-style: none; padding: 0;">
                        <li>• HTML5</li>
                        <li>• CSS3 (Slate & Emerald theme)</li>
                        <li>• JavaScript (Vanilla ES6)</li>
                        <li>• Responsive design</li>
                    </ul>
                </div>
                <div>
                    <h4>Features</h4>
                    <ul style="list-style: none; padding: 0;">
                        <li>• Role-based access</li>
                        <li>• Real-time inventory</li>
                        <li>• Automatic fines</li>
                        <li>• Comprehensive reports</li>
                    </ul>
                </div>
            </div>
        </div>
        
        <div class="card">
            <div class="card-header">
                <h3 class="card-title">📞 Support</h3>
            </div>
            <p>For technical support or questions, contact your system administrator.</p>
            <p><strong>Version:</strong> 1.0.0</p>
            <p><strong>Build Date:</strong> May 2026</p>
        </div>
    </div>

    <script src="js/app.js"></script>
    <%@ include file="../includes/footer.jsp" %>
</body>
</html>