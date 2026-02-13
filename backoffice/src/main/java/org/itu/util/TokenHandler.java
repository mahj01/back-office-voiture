package org.itu.util;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Instant;

public class TokenHandler {

    /**
     * Check whether a token exists in the database and is not expired.
     *
     * @param token the token string to validate
     * @return true if the token exists and its expires_at is in the future, false otherwise
     */
    public static boolean isTokenValid(String token) {
        if (token == null || token.isBlank()) {
            return false;
        }

        DB db = DB.fromEnv();
        try {
            db.connect();
            Connection conn = db.getConnection();
            if (conn == null) {
                System.out.println("Database connection unavailable when validating token");
                return false;
            }

            String sql = "SELECT expires_at FROM token WHERE token = ?";
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, token);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        // token not found
                        return false;
                    }

                    Timestamp expiresAt = rs.getTimestamp("expires_at");
                    if (expiresAt == null) return false;

                    Instant expiresInstant = expiresAt.toInstant();
                    Instant now = Instant.now();
                    return expiresInstant.isAfter(now);
                }
            }
        } catch (SQLException e) {
            System.out.println("Error while validating token: " + e.getMessage());
            return false;
        } finally {
            db.disconnect();
        }
    }

}
