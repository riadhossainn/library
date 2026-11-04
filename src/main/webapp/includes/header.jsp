<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<%
    // Check if user is logged in
    if (session.getAttribute("userId") == null) {
        response.sendRedirect("auth/login.jsp");
        return;
    }
    
    String username = (String) session.getAttribute("username");
    String role = (String) session.getAttribute("role");
    String context = request.getContextPath();
    String currentPage = request.getRequestURI().substring(context.length());
    
 // Determine logo link based on role
    String logoLink = context + "/index.jsp";
    if ("admin".equals(role)) {
        logoLink = context + "/admin/dashboard.jsp";
    } else if ("librarian".equals(role)) {
        logoLink = context + "/librarian/dashboard.jsp";
    } else if ("student".equals(role)) {
        logoLink = context + "/student/dashboard.jsp";
    }
%>
<nav class="navbar">
    <a href="<%= logoLink %>" class="nav-brand">
        <span>📘</span> OpenLibrary
    </a>
    <div class="nav-links">
        <%
            if ("admin".equals(role)) {
        %>
            <a href="<%= context %>/admin/dashboard.jsp" class="nav-link <%= currentPage.contains("/admin/dashboard.jsp") ? "active" : "" %>">Dashboard</a>
            <a href="<%= context %>/admin/manage_users.jsp" class="nav-link <%= currentPage.contains("/admin/manage_users.jsp") ? "active" : "" %>">Manage Users</a>
            <a href="<%= context %>/admin/reports.jsp" class="nav-link <%= currentPage.contains("/admin/reports.jsp") ? "active" : "" %>">Reports</a>
            <a href="<%= context %>/admin/system_maintenance.jsp" class="nav-link <%= currentPage.contains("/admin/system_maintenance.jsp") ? "active" : "" %>">Maintenance</a>
            <!-- Admin can also access librarian functions -->
            <a href="../librarian/approve_loans.jsp" class="nav-link">Loan Requests</a>
            <a href="<%= context %>/librarian/manage_books.jsp" class="nav-link">Manage Books</a>
            <a href="<%= context %>/librarian/process_loans.jsp" class="nav-link">Process Loans</a>
            <a href="<%= context %>/librarian/manage_fines.jsp" class="nav-link">Manage Fines</a>
        <%
            } else if ("librarian".equals(role)) {
        %>
            <a href="<%= context %>/librarian/dashboard.jsp" class="nav-link <%= currentPage.contains("/librarian/dashboard.jsp") ? "active" : "" %>">Dashboard</a>
            <a href="<%= context %>/librarian/manage_books.jsp" class="nav-link <%= currentPage.contains("/librarian/manage_books.jsp") ? "active" : "" %>">Manage Books</a>
            <a href="approve_loans.jsp" class="nav-link <%= currentPage.contains("/librarian/approve_loans.jsp") ? "active" : "" %>">Loan Requests</a>
            <a href="<%= context %>/librarian/process_loans.jsp" class="nav-link <%= currentPage.contains("/librarian/process_loans.jsp") ? "active" : "" %>">Process Loans</a>
            <a href="<%= context %>/librarian/manage_fines.jsp" class="nav-link <%= currentPage.contains("/librarian/manage_fines.jsp") ? "active" : "" %>">Manage Fines</a>
        <%
            } else if ("student".equals(role)) {
        %>
            <a href="<%= context %>/student/dashboard.jsp" class="nav-link <%= currentPage.contains("/student/dashboard.jsp") ? "active" : "" %>">Dashboard</a>
            <a href="<%= context %>/student/browse_books.jsp" class="nav-link <%= currentPage.contains("/student/browse_books.jsp") ? "active" : "" %>">Browse Books</a>
            <a href="<%= context %>/student/my_loans.jsp" class="nav-link <%= currentPage.contains("/student/my_loans.jsp") ? "active" : "" %>">My Loans</a>
        <%
            }
        %>
        <a href="<%= context %>/help/user_manual.jsp" class="nav-link">Help</a>
        <a href="<%= context %>/about.jsp" class="nav-link">About</a>
        <span class="nav-user">👤 <%= username %> (<%= role %>)</span>
        <a href="<%= context %>/logout.jsp" class="btn btn-danger">Logout</a>
    </div>
</nav>
