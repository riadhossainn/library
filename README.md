# OpenLibrary - Library Management System

A JSP/Servlet based web application for managing books, loans, fines and users with roles for Student, Librarian and Admin. Includes book browsing with Open Library covers and AI-generated summaries/recommendations via Groq.

## Features
- Role based access: Student, Librarian, Admin
- Browse books with search and category filter
- Open Library cover integration from ISBN
- Loan request workflow
- AI Summary and Recommendations per book
- Librarian: manage books, approve loans, process returns, manage fines
- Admin: user management, reports, system maintenance

## Tech Stack
- Java JSP / Servlets
- Oracle Database 21c XE `c##library`
- JDBC Oracle driver `ojdbc11.jar`
- Frontend: HTML/CSS/JavaScript
- AI: Groq API `openai/gpt-oss-120b`
- Covers: Open Library Covers API `covers.openlibrary.org`

## Project Structure
```
src/main/webapp/
  auth/           login, login_process
  student/        browse_books.jsp, dashboard.jsp, my_loans.jsp, ai_content.jsp
  librarian/      dashboard, manage_books, approve_loans, process_returns, manage_fines
  admin/          dashboard, manage_users, reports, system_maintenance
  includes/       header.jsp, footer.jsp
  css/ js/        static assets
  db/             setup.sql, 200book.sql
  WEB-INF/        web.xml, lib/
```

## Setup
1. Import project into Eclipse/IntelliJ as Dynamic Web Project
2. Oracle DB:
   - Create user `c##library` with password `1234`
   - Run `src/main/webapp/db/setup.sql` then `src/main/webapp/db/200book.sql`
3. Configure Groq API key:
   - Set context param `groq.api.key` in `WEB-INF/web.xml` or via server config
   - Do NOT hardcode keys in source
4. Deploy to Tomcat 9+ and access `http://localhost:8080/Library/`

## Default DB Connection
`jdbc:oracle:thin:@localhost:1521:xe` user `c##library` password `1234`

## Security Notes
- Do not commit secrets, API keys or DB credentials
- The PAT you shared is sensitive. Revoke it immediately and use GitHub's encrypted secrets or SSH deploy keys instead
- Use `.gitignore` to exclude `WEB-INF/lib/*.jar`, `*.war`, IDE files

## Running Tests
`src/main/webapp/test_conn.jsp` and `test_db.jsp` can verify DB connectivity.

## License
Private project.
