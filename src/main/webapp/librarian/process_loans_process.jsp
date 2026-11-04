<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, java.text.SimpleDateFormat, java.util.Date" %>
<%
    // Verify librarian access
     if (!"admin".equals(session.getAttribute("role")) && !"librarian".equals(session.getAttribute("role"))) {
        response.sendRedirect("../auth/login.jsp");
        return;
    }

    String action = request.getParameter("action");
    String message = "";
    String messageType = "";

    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    try {
        Class.forName("oracle.jdbc.OracleDriver");
        String url = "jdbc:oracle:thin:@localhost:1521:xe";
        conn = DriverManager.getConnection(url, "c##library", "1234");

        if ("issue".equals(action)) {
            String username = request.getParameter("username");
            String bookIdStr = request.getParameter("book_id");
            String dueDate = request.getParameter("due_date");

            int bookId = Integer.parseInt(bookIdStr);

            // Check if user exists
            pstmt = conn.prepareStatement("SELECT user_id, role FROM c##library.users WHERE username = ?");
            pstmt.setString(1, username);
            rs = pstmt.executeQuery();
            if (!rs.next()) {
                message = "User not found: " + username;
                messageType = "error";
            } else if (!"student".equals(rs.getString("role"))) {
                message = "User is not a student: " + username;
                messageType = "error";
            } else {
                int userId = rs.getInt("user_id");
                rs.close();
                pstmt.close();

                // Check if book exists and is available
                pstmt = conn.prepareStatement("SELECT available_copies FROM c##library.books WHERE book_id = ?");
                pstmt.setInt(1, bookId);
                rs = pstmt.executeQuery();
                if (!rs.next()) {
                    message = "Book not found: " + bookId;
                    messageType = "error";
                } else if (rs.getInt("available_copies") <= 0) {
                    message = "Book is not available: " + bookId;
                    messageType = "error";
                } else {
                    rs.close();
                    pstmt.close();

                    // Check if user already has this book borrowed
                    pstmt = conn.prepareStatement(
                        "SELECT COUNT(*) as count FROM c##library.issues WHERE user_id = ? AND book_id = ? AND status = 'active'"
                    );
                    pstmt.setInt(1, userId);
                    pstmt.setInt(2, bookId);
                    rs = pstmt.executeQuery();
                    int existingCount = 0;
                    if (rs.next()) existingCount = rs.getInt("count");
                    rs.close();
                    pstmt.close();

                    if (existingCount > 0) {
                        message = "User already has this book borrowed.";
                        messageType = "error";
                    } else {
                        // Check if user has reached borrowing limit (5 books)
                        pstmt = conn.prepareStatement(
                            "SELECT COUNT(*) as count FROM c##library.issues WHERE user_id = ? AND status = 'active'"
                        );
                        pstmt.setInt(1, userId);
                        rs = pstmt.executeQuery();
                        int currentLoans = 0;
                        if (rs.next()) currentLoans = rs.getInt("count");
                        rs.close();
                        pstmt.close();

                        if (currentLoans >= 5) {
                            message = "User has reached maximum borrowing limit (5 books).";
                            messageType = "error";
                        } else {
                            // Issue the book
                            conn.setAutoCommit(false);

                            // Insert into issues table
                            pstmt = conn.prepareStatement(
                                "INSERT INTO c##library.issues (user_id, book_id, issue_date, due_date, status) VALUES (?, ?, SYSDATE, ?, 'active')"
                            );
                            pstmt.setInt(1, userId);
                            pstmt.setInt(2, bookId);
                            pstmt.setDate(3, java.sql.Date.valueOf(dueDate));
                            pstmt.executeUpdate();
                            pstmt.close();

                            // Decrease available copies
                            pstmt = conn.prepareStatement(
                                "UPDATE c##library.books SET available_copies = available_copies - 1 WHERE book_id = ?"
                            );
                            pstmt.setInt(1, bookId);
                            pstmt.executeUpdate();
                            pstmt.close();

                            conn.commit();
                            message = "Book issued successfully!";
                            messageType = "success";
                        }
                    }
                }
            }
        }
        else if ("return".equals(action)) {
            String issueIdStr = request.getParameter("issue_id");
            int issueId = Integer.parseInt(issueIdStr);

            // Get issue details
            pstmt = conn.prepareStatement(
                "SELECT user_id, book_id, due_date, status FROM c##library.issues WHERE issue_id = ?"
            );
            pstmt.setInt(1, issueId);
            rs = pstmt.executeQuery();
            if (!rs.next()) {
                message = "Loan record not found.";
                messageType = "error";
            } else if (!"active".equals(rs.getString("status"))) {
                message = "Loan is not active.";
                messageType = "error";
            } else {
                int userId = rs.getInt("user_id");
                int bookId = rs.getInt("book_id");
                Date dueDate = rs.getDate("due_date");
                rs.close();
                pstmt.close();

                // Calculate fine if overdue
                Date currentDate = new Date();
                long diffInMillies = currentDate.getTime() - dueDate.getTime();
                long daysOverdue = diffInMillies / (24 * 60 * 60 * 1000);
                double fineAmount = 0.0;

                if (daysOverdue > 0) {
                    fineAmount = daysOverdue * 2.0; // ₹2 per day
                }

                conn.setAutoCommit(false);

                // Update issue record
                pstmt = conn.prepareStatement(
                    "UPDATE c##library.issues SET return_date = SYSDATE, status = 'returned' WHERE issue_id = ?"
                );
                pstmt.setInt(1, issueId);
                pstmt.executeUpdate();
                pstmt.close();

                // Increase available copies
                pstmt = conn.prepareStatement(
                    "UPDATE c##library.books SET available_copies = available_copies + 1 WHERE book_id = ?"
                );
                pstmt.setInt(1, bookId);
                pstmt.executeUpdate();
                pstmt.close();

                // If fine is applicable, insert into fines table
                if (fineAmount > 0) {
                    pstmt = conn.prepareStatement(
                        "INSERT INTO c##library.fines (issue_id, amount, fine_date, status) VALUES (?, ?, SYSDATE, 'pending')"
                    );
                    pstmt.setInt(1, issueId);
                    pstmt.setDouble(2, fineAmount);
                    pstmt.executeUpdate();
                    pstmt.close();
                }

                conn.commit();
                message = "Book returned successfully!" + (fineAmount > 0 ? " Fine applied: ₹" + fineAmount : "");
                messageType = "success";
            }
        }
    } catch (SQLException e) {
        if (conn != null) {
            try {
                conn.rollback();
            } catch (SQLException rollbackEx) {
                rollbackEx.printStackTrace();
            }
        }
        message = "Database error: " + e.getMessage();
        messageType = "error";
        e.printStackTrace();
    } catch (Exception e) {
        message = "Error: " + e.getMessage();
        messageType = "error";
        e.printStackTrace();
    } finally {
        if (pstmt != null) try { pstmt.close(); } catch (SQLException ignored) {}
        if (rs != null) try { rs.close(); } catch (SQLException ignored) {}
        if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
    }

    // Redirect back to process_loans.jsp with message
    response.sendRedirect("process_loans.jsp?message=" + java.net.URLEncoder.encode(message, "UTF-8") + "&type=" + messageType);
%>