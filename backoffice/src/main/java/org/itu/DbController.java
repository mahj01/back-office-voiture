package org.itu;

import com.itu.*;
import org.itu.util.DB;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

@ControllerAnnotation(url = "db")
public class DbController {

    @UrlAnnotation(url = "testConnection")
    public void testConnection(HttpServletRequest req, HttpServletResponse res) throws IOException {
        // Default connection values matching database-scripts/0602_init.sql
        String host = "localhost";
        int port = 5432;
        String database = "voiture_reservation";
        String user = "app_dev";
        String password = "dev_pwd";

        DB db = new DB(host, port, database, user, password);
        db.connect();

        if (db.getConnection() != null) {
            res.getWriter().write("DB OK: connected to " + database + "@" + host + ":" + port);
        } else {
            res.getWriter().write("DB ERROR: cannot connect to " + database + "@" + host + ":" + port);
        }

        db.disconnect();
    }
}
