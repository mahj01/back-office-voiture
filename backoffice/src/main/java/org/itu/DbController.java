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
        DB db = DB.fromEnv();
        db.connect();

        if (db.getConnection() != null) {
            res.getWriter().write("DB OK: connected");
        } else {
            res.getWriter().write("DB ERROR: cannot connect");
        }

        db.disconnect();
    }
}
