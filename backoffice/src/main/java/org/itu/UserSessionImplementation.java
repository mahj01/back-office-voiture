package org.itu;

import com.security.UserSession;

import java.util.Set;
import java.util.Collections;
import java.util.HashSet;
import com.util.Session;

public class UserSessionImplementation implements UserSession {
    // Hold a reference to the session that contains user data
    private final Session session;

    // Keys we expect in the Session
    private static final String KEY_USER_ID = "userSession";
    private static final String KEY_USER = "user";
    private static final String KEY_ROLES = "roles";
    private static final String KEY_LAST_ACCESS = "lastAccessTime";

    // Constructor used when a Session is available
    public UserSessionImplementation(Session session) {
        this.session = session;
    }

    // Backwards-compatible default constructor (keeps previous behavior)
    public UserSessionImplementation() {
        this.session = null;
    }

    @Override
    public boolean isAuthenticated() {
        if (session == null) return false;
        Object id = session.get(KEY_USER_ID);
        if (id == null) return false;
        if (id instanceof Number) return ((Number) id).longValue() > 0;
        // allow string ids too
        if (id instanceof String) return !((String) id).isBlank();
        return true;
    }

    @Override
    public Object getUser() {
        if (session == null) return null;
        return session.get(KEY_USER);
    }

    @Override
    @SuppressWarnings("unchecked")
    public Set<String> getRoles() {
        if (session == null) return Collections.emptySet();
        Object roles = session.get(KEY_ROLES);
        if (roles == null) return Collections.emptySet();
        if (roles instanceof Set) {
            return (Set<String>) roles;
        }
        // If roles stored as comma-separated string, parse it
        if (roles instanceof String) {
            String s = (String) roles;
            if (s.isBlank()) return Collections.emptySet();
            String[] parts = s.split(",");
            Set<String> out = new HashSet<>();
            for (String p : parts) out.add(p.trim());
            return out;
        }
        return Collections.emptySet();
    }

    @Override
    public long getLastAccessTime() {
        if (session == null) return 0L;
        Object t = session.get(KEY_LAST_ACCESS);
        if (t == null) return 0L;
        if (t instanceof Number) return ((Number) t).longValue();
        if (t instanceof String) {
            try {
                return Long.parseLong((String) t);
            } catch (NumberFormatException ignore) {
                return 0L;
            }
        }
        return 0L;
    }
}
