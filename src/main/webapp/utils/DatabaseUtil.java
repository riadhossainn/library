package utils;

import java.sql.*;

public class DatabaseUtil {
    
    private static final String DRIVER = "oracle.jdbc.OracleDriver";
    private static final String URL = "jdbc:oracle:thin:@localhost:1521:xe";
    private static final String USERNAME = "c##library";
    private static final String PASSWORD = "1234";
    
    static {
        try {
            Class.forName(DRIVER);
        } catch (ClassNotFoundException e) {
            throw new RuntimeException("Oracle JDBC Driver not found", e);
        }
    }
    
    /**
     * Get database connection
     */
    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(URL, USERNAME, PASSWORD);
    }
    
    /**
     * Close connection safely
     */
    public static void closeConnection(Connection conn) {
        if (conn != null) {
            try {
                conn.close();
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
    }
    
    /**
     * Close prepared statement safely
     */
    public static void closeStatement(PreparedStatement pstmt) {
        if (pstmt != null) {
            try {
                pstmt.close();
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
    }
    
    /**
     * Close result set safely
     */
    public static void closeResultSet(ResultSet rs) {
        if (rs != null) {
            try {
                rs.close();
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
    }
    
    /**
     * Close all resources safely
     */
    public static void closeResources(Connection conn, PreparedStatement pstmt, ResultSet rs) {
        closeResultSet(rs);
        closeStatement(pstmt);
        closeConnection(conn);
    }
}