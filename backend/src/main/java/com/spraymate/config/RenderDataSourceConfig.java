package com.spraymate.config;

import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.context.annotation.Profile;

import javax.sql.DataSource;
import java.net.URI;
import java.net.URISyntaxException;

/**
 * Converts Render's DATABASE_URL (postgresql://user:pass@host:port/db)
 * into a JDBC-compatible datasource for Spring Boot.
 *
 * Active only when the "render" profile is set (SPRING_PROFILES_ACTIVE=render).
 * Locally, the default profile uses DB_URL / DB_USERNAME / DB_PASSWORD from .env.
 */
@Configuration
@Profile("render")
public class RenderDataSourceConfig {

    @Bean
    @Primary
    public DataSource dataSource() throws URISyntaxException {
        String databaseUrl = System.getenv("DATABASE_URL");
        if (databaseUrl == null || databaseUrl.isBlank()) {
            throw new IllegalStateException(
                    "DATABASE_URL environment variable is not set. " +
                    "This is required when running with the 'render' profile.");
        }

        URI dbUri = new URI(databaseUrl);
        String userInfo = dbUri.getUserInfo();
        String username = userInfo.split(":")[0];
        String password = userInfo.split(":")[1];
        int port = dbUri.getPort() == -1 ? 5432 : dbUri.getPort();
        String jdbcUrl = "jdbc:postgresql://" + dbUri.getHost()
                + ":" + port
                + dbUri.getPath()
                + "?sslmode=require";

        DataSourceProperties properties = new DataSourceProperties();
        properties.setUrl(jdbcUrl);
        properties.setUsername(username);
        properties.setPassword(password);
        properties.setDriverClassName("org.postgresql.Driver");

        return properties.initializeDataSourceBuilder().build();
    }
}
