<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ include file="../includes/header.jsp" %>
<%!
    public String escapeHtml(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;")
                .replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }
%>
<%
    if (!"student".equals(session.getAttribute("role"))) {
        response.sendRedirect("../auth/login.jsp");
        return;
    }

    String search = request.getParameter("search");
    String category = request.getParameter("category");

    String bookId = request.getParameter("request_book");
    if (bookId != null && "POST".equalsIgnoreCase(request.getMethod())) {
        Connection conn = null; PreparedStatement pstmt = null; ResultSet rs = null;
        try {
            Class.forName("oracle.jdbc.OracleDriver");
            conn = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1521:xe", "c##library", "1234");

            pstmt = conn.prepareStatement("SELECT available_copies FROM c##library.books WHERE book_id = ?");
            pstmt.setInt(1, Integer.parseInt(bookId));
            rs = pstmt.executeQuery();

            if (rs.next() && rs.getInt("available_copies") > 0) {
                pstmt = conn.prepareStatement("INSERT INTO c##library.loan_requests (user_id, book_id, status) VALUES (?, ?, 'pending')");
                pstmt.setInt(1, (Integer) session.getAttribute("userId"));
                pstmt.setInt(2, Integer.parseInt(bookId));
                pstmt.executeUpdate();
                response.sendRedirect("browse_books.jsp?message=Loan request submitted successfully&status=success");
            } else {
                response.sendRedirect("browse_books.jsp?message=Book not available&status=error");
            }
        } catch (Exception e) {
            response.sendRedirect("browse_books.jsp?message=Error submitting request&status=error");
        } finally {
            if (rs != null) try { rs.close(); } catch (SQLException ignored) {}
            if (pstmt != null) try { pstmt.close(); } catch (SQLException ignored) {}
            if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
        }
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Browse Books - OpenLibrary</title>
    <link rel="stylesheet" href="../css/style.css">
    <style>
        .book-cover {
            width: 100%; max-width: 160px; height: 220px; object-fit: cover; 
            border-radius: 6px; box-shadow: 0 4px 12px rgba(0,0,0,0.1); margin-bottom: 0.8rem;
            background-color: #f1f5f9;
        }
        .book-summary {
            background:#f8fafc; padding:1rem; border-radius:6px; margin:0.5rem 0;
            font-size:0.9rem; line-height:1.6; border-left:3px solid #3b82f6; display:none;
        }
        .ai-badge {
            background:#3b82f6; color:#fff; padding:0.2rem 0.5rem;
            border-radius:4px; font-size:0.7rem; margin-left:0.5rem;
        }
        .recommendations {
            background:#fefce8; padding:0.8rem; border-radius:6px; margin:0.5rem 0;
            font-size:0.85rem; border-left:3px solid #eab308; display:none;
        }
        .summary-toggle {
            background:#3b82f6; color:#fff; border:none; padding:0.3rem 0.6rem;
            border-radius:4px; cursor:pointer; font-size:0.8rem;
            margin-top:0.5rem; margin-right:0.3rem;
        }
        .summary-toggle:hover { background:#2563eb; }
        .loading { color: #666; font-style: italic; }
        .loading::after { content: '...'; animation: dots 1.5s infinite; }
        @keyframes dots {
            0%, 20% { content: '.'; } 40% { content: '..'; } 60%, 100% { content: '...'; }
        }
    </style>
</head>
<body>
<div class="container">
    <div class="card">
        <div class="card-header">
            <h2 class="card-title">📚 Browse Books</h2>
        </div>

        <% if (request.getParameter("message") != null) { %>
            <div class="alert alert-<%= escapeHtml(request.getParameter("status") != null ? request.getParameter("status") : "info") %>">
                <%= escapeHtml(request.getParameter("message")) %>
            </div>
        <% } %>

        <form method="GET" style="display:flex; gap:1rem; margin-bottom:1rem;">
            <div class="form-group" style="flex:1;">
                <input type="text" name="search" placeholder="Search by title or author..."
                       value="<%= escapeHtml(search != null ? search : "") %>">
            </div>
            <div class="form-group">
                <select name="category">
                    <option value="">All Categories</option>
                    <% String[] cats = {"Technology","Programming","Self-Help","Science","Literature","History","Finance","Strategy"};
                       for (String c : cats) { %>
                        <option value="<%= c %>" <%= c.equals(category) ? "selected" : "" %>><%= c %></option>
                    <% } %>
                </select>
            </div>
            <button type="submit" class="btn btn-primary">Search</button>
            <a href="browse_books.jsp" class="btn btn-secondary">Clear</a>
        </form>

        <div style="display:grid; grid-template-columns:repeat(auto-fill, minmax(280px, 1fr)); gap:1.2rem;">
            <%
                Connection conn = null; PreparedStatement pstmt = null; ResultSet rs = null;
                try {
                    conn = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1521:xe", "c##library", "1234");

                    StringBuilder sql = new StringBuilder(
                        "SELECT book_id, title, author, isbn, total_copies, available_copies, category, description "
                        + "FROM c##library.books WHERE 1=1");
                    if (search != null && !search.trim().isEmpty())
                        sql.append(" AND (UPPER(title) LIKE UPPER('%' || ? || '%') OR UPPER(author) LIKE UPPER('%' || ? || '%'))");
                    if (category != null && !category.trim().isEmpty())
                        sql.append(" AND UPPER(category) = UPPER(?)");
                    sql.append(" ORDER BY category, title");

                    pstmt = conn.prepareStatement(sql.toString());
                    int p = 1;
                    if (search != null && !search.trim().isEmpty()) {
                        pstmt.setString(p++, search); pstmt.setString(p++, search);
                    }
                    if (category != null && !category.trim().isEmpty()) {
                        pstmt.setString(p++, category);
                    }

                    rs = pstmt.executeQuery();
                    int bookCount = 0;

                    while (rs.next()) {
                        bookCount++;
                        int id = rs.getInt("book_id");
                        String title = escapeHtml(rs.getString("title"));
                        String author = escapeHtml(rs.getString("author"));
                        String cat = escapeHtml(rs.getString("category"));
                        String rawIsbn = rs.getString("isbn");
                        String desc = rs.getString("description");
                        int avail = rs.getInt("available_copies");
                        int total = rs.getInt("total_copies");
                        
                        // ✅ Open Library cover URL
                        String coverUrl = "https://via.placeholder.com/160x220/e2e8f0/64748b?text=No+Cover";
                        if (rawIsbn != null && !rawIsbn.trim().isEmpty() && !rawIsbn.equalsIgnoreCase("N/A")) {
                            String cleanIsbn = rawIsbn.replace("-", "").replace(" ", "");
                            coverUrl = "https://covers.openlibrary.org/b/isbn/" + cleanIsbn + "-M.jpg";
                        }
            %>
                <div class="card" style="padding:1rem; height:auto; display:flex; flex-direction:column;">
                    <div style="text-align:center;">
                        <img src="<%= coverUrl %>" 
                             alt="<%= title %>" 
                             class="book-cover"
                             onerror="this.src='https://via.placeholder.com/160x220/e2e8f0/64748b?text=No+Cover';">
                    </div>
                    
                    <h4 style="margin:0 0 0.3rem 0; font-size:1.1rem;"><%= title %></h4>
                    <p style="color:var(--text-light); font-size:0.9rem; margin:0 0 0.5rem 0;"><strong>by</strong> <%= author %></p>

                    <% if (rawIsbn != null && !rawIsbn.isEmpty()) { %>
                        <p style="font-size:0.8rem; color:#666; margin:0 0 0.3rem 0;">ISBN: <%= escapeHtml(rawIsbn) %></p>
                    <% } %>

                    <p style="font-size:0.85rem; color:#666; margin:0 0 0.5rem 0;">
                        Available: <strong style="color:<%= avail > 0 ? "#16a34a" : "#dc2626" %>"><%= avail %>/<%= total %></strong>
                    </p>

                    <% if (cat != null && !cat.isEmpty()) { %>
                        <span style="background:#e0e7ff; color:#3730a3; padding:0.2rem 0.5rem; border-radius:4px; font-size:0.75rem; font-weight:600; display:inline-block; margin-bottom:0.5rem;">
                            <%= cat %>
                        </span>
                    <% } %>

                    <div style="margin-top:auto;">
                        <button class="summary-toggle" onclick="loadAi(this, '<%= id %>', 'summary')">📄 Show Summary</button>
                        <button class="summary-toggle" onclick="loadAi(this, '<%= id %>', 'recommend')">📚 Recommendations</button>

                        <div id="summary-<%= id %>" class="book-summary"
                             data-title="<%= title %>" data-author="<%= author %>" data-category="<%= cat %>"></div>

                        <div id="recommend-<%= id %>" class="recommendations"
                             data-title="<%= title %>" data-author="<%= author %>" data-category="<%= cat %>"></div>

                        <% if (desc != null && !desc.isEmpty()) { %>
                            <p style="font-size:0.8rem; margin:0.5rem 0; line-height:1.4; color:#555;">
                                <strong>Original:</strong> <%= escapeHtml(desc.length() > 80 ? desc.substring(0,80) + "..." : desc) %>
                            </p>
                        <% } %>

                        <% if (avail > 0) { %>
                            <form method="POST" style="margin-top:0.5rem;">
                                <input type="hidden" name="request_book" value="<%= id %>">
                                <button type="submit" class="btn btn-primary" style="width:100%;"
                                        onclick="return confirm('Request loan for this book?')">Request Loan</button>
                            </form>
                        <% } else { %>
                            <button class="btn btn-secondary" style="width:100%;" disabled>Not Available</button>
                        <% } %>
                    </div>
                </div>
            <%
                    }
                    if (bookCount == 0) {
                        out.println("<div class='card' style='text-align:center; padding:2rem; grid-column:1/-1;'>"
                            + "<p>No books found matching your criteria.</p></div>");
                    }
                } catch (Exception e) {
                    out.println("<div class='card' style='text-align:center; padding:2rem; grid-column:1/-1;'>"
                        + "<p style='color:red;'>Error loading books: " + e.getMessage() + "</p></div>");
                } finally {
                    if (rs != null) try { rs.close(); } catch (SQLException ignored) {}
                    if (pstmt != null) try { pstmt.close(); } catch (SQLException ignored) {}
                    if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
                }
            %>
        </div>
    </div>
</div>

<script>
async function loadAi(button, bookId, type) {
    var divId = (type === 'recommend' ? 'recommend-' : 'summary-') + bookId;
    var div = document.getElementById(divId);

    if (div.style.display === 'block') {
        div.style.display = 'none';
        button.textContent = (type === 'recommend') ? '📚 Recommendations' : '📄 Show Summary';
        return;
    }

    div.style.display = 'block';
    button.textContent = '❌ Hide';

    if (div.dataset.loaded === 'true') return;

    div.innerHTML = '<span class="loading">Generating AI response</span>';

    var params = new URLSearchParams({
        type: type,
        title: div.dataset.title,
        author: div.dataset.author,
        category: div.dataset.category
    });

    try {
        var res = await fetch('ai_content.jsp?' + params.toString());
        if (!res.ok) throw new Error('HTTP error ' + res.status);
        var data = await res.json();
        if (data.content) {
            if (type === 'recommend') {
                div.innerHTML = '<strong>You might also like:</strong><br>' + data.content;
            } else {
                div.innerHTML = '<strong>About this book:</strong> <span class="ai-badge">AI</span><br><br>' + data.content;
            }
            div.dataset.loaded = 'true';
        } else {
            div.innerHTML = 'No content available.';
        }
    } catch (e) {
        console.error('Error loading AI content:', e);
        div.innerHTML = 'Could not load content. Please try again.';
    }
}
</script>
</body>
</html>