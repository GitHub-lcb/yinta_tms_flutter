package com.yinta.mysqlservice.service;

import com.yinta.mysqlservice.config.DatabaseConfig;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.sql.*;
import java.util.*;

@Slf4j
@Service
public class DatabaseService {
    private final Map<String, Connection> connections = new HashMap<>();

    public String connect(DatabaseConfig config) throws SQLException {
        String url = String.format("jdbc:mysql://%s:%d/%s?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC",
                config.getHost(),
                config.getPort(),
                config.getDatabase() != null ? config.getDatabase() : "");

        log.info("Connecting to MySQL with URL: {}", url);
        try {
            Connection connection = DriverManager.getConnection(url, config.getUsername(), config.getPassword());
            String connectionId = UUID.randomUUID().toString();
            connections.put(connectionId, connection);
            log.info("Successfully connected to MySQL. Connection ID: {}", connectionId);
            return connectionId;
        } catch (SQLException e) {
            log.error("Failed to connect to MySQL: {}", e.getMessage());
            throw e;
        }
    }

    public void disconnect(String connectionId) {
        Connection connection = connections.remove(connectionId);
        if (connection != null) {
            try {
                connection.close();
            } catch (SQLException e) {
                log.error("Error closing connection", e);
            }
        }
    }

    public List<String> getDatabases(String connectionId) throws SQLException {
        Connection connection = connections.get(connectionId);
        if (connection == null) {
            throw new IllegalStateException("Connection not found");
        }

        List<String> databases = new ArrayList<>();
        try (Statement stmt = connection.createStatement();
             ResultSet rs = stmt.executeQuery("SHOW DATABASES")) {
            while (rs.next()) {
                databases.add(rs.getString(1));
            }
        }
        return databases;
    }

    public List<String> getTables(String connectionId, String database) throws SQLException {
        Connection connection = connections.get(connectionId);
        if (connection == null) {
            throw new IllegalStateException("Connection not found");
        }

        connection.setCatalog(database);
        List<String> tables = new ArrayList<>();
        try (Statement stmt = connection.createStatement();
             ResultSet rs = stmt.executeQuery("SHOW TABLES")) {
            while (rs.next()) {
                tables.add(rs.getString(1));
            }
        }
        return tables;
    }

    public List<Map<String, Object>> executeQuery(String connectionId, String query) throws SQLException {
        Connection connection = connections.get(connectionId);
        if (connection == null) {
            throw new IllegalStateException("Connection not found");
        }

        log.info("Executing query: {}", query);
        
        // Check if the query is a SELECT query
        String trimmedQuery = query.trim().toLowerCase();
        if (!trimmedQuery.startsWith("select")) {
            return executeUpdate(connectionId, query);
        }

        List<Map<String, Object>> results = new ArrayList<>();
        List<String> columnOrder = new ArrayList<>();
        try (Statement stmt = connection.createStatement();
             ResultSet rs = stmt.executeQuery(query)) {
            ResultSetMetaData metaData = rs.getMetaData();
            int columnCount = metaData.getColumnCount();

            // Store column names in order
            for (int i = 1; i <= columnCount; i++) {
                columnOrder.add(metaData.getColumnName(i));
            }

            while (rs.next()) {
                Map<String, Object> row = new LinkedHashMap<>();  // Use LinkedHashMap to maintain order
                for (String columnName : columnOrder) {
                    row.put(columnName, rs.getObject(columnName));
                }
                results.add(row);
            }
            
            // Add column order to the first row as metadata
            if (!results.isEmpty()) {
                results.get(0).put("__columnOrder", columnOrder);
            }
            
            log.info("Query executed successfully, returned {} rows", results.size());
            return results;
        } catch (SQLException e) {
            log.error("Error executing query: {}", e.getMessage());
            throw new SQLException("Query execution failed: " + e.getMessage());
        }
    }

    public List<Map<String, Object>> executeUpdate(String connectionId, String query) throws SQLException {
        Connection connection = connections.get(connectionId);
        if (connection == null) {
            throw new IllegalStateException("Connection not found");
        }

        log.info("Executing update query: {}", query);
        try (Statement stmt = connection.createStatement()) {
            int rowsAffected = stmt.executeUpdate(query);
            log.info("Update executed successfully, {} rows affected", rowsAffected);
            
            // Return result in the same format as executeQuery
            List<Map<String, Object>> results = new ArrayList<>();
            Map<String, Object> result = new HashMap<>();
            result.put("rowsAffected", rowsAffected);
            results.add(result);
            return results;
        } catch (SQLException e) {
            log.error("Error executing update: {}", e.getMessage());
            throw new SQLException("Update execution failed: " + e.getMessage());
        }
    }

    public void selectDatabase(String connectionId, String database) throws SQLException {
        Connection connection = connections.get(connectionId);
        if (connection == null) {
            throw new IllegalStateException("Connection not found");
        }
        connection.setCatalog(database);
    }

    public List<Map<String, Object>> getTableStructure(String connectionId, String database, String table) throws SQLException {
        Connection connection = connections.get(connectionId);
        if (connection == null) {
            throw new IllegalStateException("Connection not found");
        }

        connection.setCatalog(database);
        List<Map<String, Object>> columns = new ArrayList<>();
        
        try (Statement stmt = connection.createStatement();
             ResultSet rs = stmt.executeQuery("SHOW FULL COLUMNS FROM `" + table + "`")) {
            ResultSetMetaData metaData = rs.getMetaData();
            int columnCount = metaData.getColumnCount();

            while (rs.next()) {
                Map<String, Object> column = new HashMap<>();
                for (int i = 1; i <= columnCount; i++) {
                    column.put(metaData.getColumnName(i), rs.getObject(i));
                }
                columns.add(column);
            }
        }
        return columns;
    }

    public List<Map<String, Object>> getTableIndexes(String connectionId, String database, String table) throws SQLException {
        Connection connection = connections.get(connectionId);
        if (connection == null) {
            throw new IllegalStateException("Connection not found");
        }

        connection.setCatalog(database);
        List<Map<String, Object>> indexes = new ArrayList<>();
        
        try (Statement stmt = connection.createStatement();
             ResultSet rs = stmt.executeQuery("SHOW INDEX FROM `" + table + "`")) {
            ResultSetMetaData metaData = rs.getMetaData();
            int columnCount = metaData.getColumnCount();

            while (rs.next()) {
                Map<String, Object> index = new HashMap<>();
                for (int i = 1; i <= columnCount; i++) {
                    index.put(metaData.getColumnName(i), rs.getObject(i));
                }
                indexes.add(index);
            }
        }
        return indexes;
    }

    public void alterTable(String connectionId, String database, String table, String alterSql) throws SQLException {
        Connection connection = connections.get(connectionId);
        if (connection == null) {
            throw new IllegalStateException("Connection not found");
        }

        connection.setCatalog(database);
        try (Statement stmt = connection.createStatement()) {
            stmt.executeUpdate(alterSql);
        }
    }
} 