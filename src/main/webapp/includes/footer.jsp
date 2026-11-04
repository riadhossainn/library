<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!-- Footer -->
<footer class="site-footer">
    <div class="footer-content">
        <div class="footer-section">
            <h4>📘 OpenLibrary</h4>
            <p>A pure JSP-based library management system</p>
        </div>
        <div class="footer-section">
            <h4>Quick Links</h4>
            <ul>
                <li><a href="help/user_manual.jsp">User Manual</a></li>
                <li><a href="about.jsp">About Project</a></li>
                
            </ul>
        </div>
        <div class="footer-section">
            <h4>Academic</h4>
            <p>Department of Computer Science<br>
            University of Scholars<br>
            CSE 3108 - Integrated Design Project</p>
        </div>
    </div>
    <div class="footer-bottom">
        © 2026 OpenLibrary. All rights reserved.
    </div>
</footer>

<style>
/* ===== FOOTER ===== */
.site-footer {
    background: #0F172A;
    color: #CBD5E1;
    padding: 2rem 0;
    margin-top: auto;
}

.footer-content {
    max-width: 1200px;
    margin: 0 auto;
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 2rem;
    padding: 0 1.5rem;
}

.footer-section h4 {
    color: white;
    margin-bottom: 1rem;
    font-size: 1rem;
}

.footer-section p, .footer-section ul {
    font-size: 0.9rem;
    line-height: 1.6;
}

.footer-section ul {
    list-style: none;
    padding: 0;
}

.footer-section ul li {
    margin-bottom: 0.5rem;
}

.footer-section a {
    color: #94A3B8;
    text-decoration: none;
    transition: color 0.3s;
}

.footer-section a:hover {
    color: #10B981;
}

.footer-bottom {
    text-align: center;
    padding: 1.5rem 0;
    margin: 2rem 0 0;
    border-top: 1px solid #334155;
    font-size: 0.85rem;
    color: #647481;
}
</style>