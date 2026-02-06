package org.itu.util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DB {

    private String host;
    private String database;
    private String user;
    private String password;
    private int port;

    private Connection connection;

    public DB(String host, int port, String database, String user, String password) {
        this.host = host;
        this.port = port;
        this.database = database;
        this.user = user;
        this.password = password;
        this.connection = null;
    }

    public void connect() {
        try {
            Class.forName("org.postgresql.Driver");
            String url = "jdbc:postgresql://" + host + ":" + port + "/" + database;
            connection = DriverManager.getConnection(url, user, password);
            System.out.println("Connexion réussie à la base '" + database + "' sur " + host + ":" + port);
        } catch (ClassNotFoundException e) {
            System.out.println("Driver PostgreSQL non trouvé : " + e.getMessage());
            connection = null;
        } catch (SQLException e) {
            System.out.println("Erreur de connexion : " + e.getMessage());
            connection = null;
        }
    }

    public void disconnect() {
        if (connection != null) {
            try {
                connection.close();
                System.out.println("Connexion fermée.");
            } catch (SQLException e) {
                System.out.println("Erreur lors de la fermeture de la connexion : " + e.getMessage());
            }
        }
    }

    public Connection getConnection() {
        return connection;
    }

}
