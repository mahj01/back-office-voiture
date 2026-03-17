CREATE TABLE token (
    id SERIAL PRIMARY KEY,
    token VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP NOT NULL
);

INSERT INTO token (token, expires_at) VALUES ('abc123', NOW() + INTERVAL '1 day');
INSERT INTO token (token, expires_at) VALUES ('def456', NOW() - INTERVAL '1 day');