package org.itu.util;

import io.github.cdimascio.dotenv.Dotenv;

/**
 * Centralizes DB configuration loading.
 *
 * Resolution order:
 * 1) .env file (loaded from working dir / classpath)
 * 2) System environment variables
 * 3) Provided defaults
 */
public final class DbConfig {

    private final String host;
    private final int port;
    private final String database;
    private final String user;
    private final String password;

    public DbConfig(String host, int port, String database, String user, String password) {
        this.host = host;
        this.port = port;
        this.database = database;
        this.user = user;
        this.password = password;
    }

    public static DbConfig fromEnv() {
        // Keep backward-compatible defaults (matching the previous hardcoded values)
        String host = getEnv("DB_HOST", "localhost");
        int port = parseInt(getEnv("DB_PORT", "5432"), 5432);
        String database = getEnv("DB_NAME", "voiture_reservation");
        String user = getEnv("DB_USER", "app_dev");
        String password = getEnv("DB_PASSWORD", "dev_pwd");

        return new DbConfig(host, port, database, user, password);
    }

    private static String getEnv(String key, String defaultValue) {
        try {
            Dotenv dotenv = Dotenv.configure()
                    .ignoreIfMissing()
                    .load();
            String v = dotenv.get(key);
            if (v != null && !v.isBlank()) return v;
        } catch (Exception ignored) {
            // If dotenv can't load for some reason, fall back to System.getenv()
        }

        String sys = System.getenv(key);
        if (sys != null && !sys.isBlank()) return sys;

        return defaultValue;
    }

    private static int parseInt(String value, int defaultValue) {
        try {
            return Integer.parseInt(value);
        } catch (Exception e) {
            return defaultValue;
        }
    }

    public String getHost() {
        return host;
    }

    public int getPort() {
        return port;
    }

    public String getDatabase() {
        return database;
    }

    public String getUser() {
        return user;
    }

    public String getPassword() {
        return password;
    }
}

