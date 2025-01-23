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

    public Map<String, Object> getTables(String connectionId, String database, Integer offset, Integer limit) throws SQLException {
        Connection connection = connections.get(connectionId);
        if (connection == null) {
            throw new IllegalStateException("Connection not found");
        }

        connection.setCatalog(database);
        Map<String, Object> result = new HashMap<>();
        
        // 获取总表数
        try (Statement stmt = connection.createStatement();
             ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '" + database + "'")) {
            if (rs.next()) {
                result.put("total", rs.getInt(1));
            }
        }

        // 构建分页查询
        StringBuilder query = new StringBuilder("SELECT table_name FROM information_schema.tables WHERE table_schema = '" + database + "'");
        if (limit != null) {
            query.append(" LIMIT ").append(limit);
            if (offset != null) {
                query.append(" OFFSET ").append(offset);
            }
        }

        List<String> tables = new ArrayList<>();
        try (Statement stmt = connection.createStatement();
             ResultSet rs = stmt.executeQuery(query.toString())) {
            while (rs.next()) {
                tables.add(rs.getString(1));
            }
        }
        
        result.put("tables", tables);
        return result;
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

    /// 获取建表语句方法
    /// 获取指定表的建表语句
    ///
    /// @param connectionId 连接ID
    /// @param database 数据库名称
    /// @param table 表名
    /// @return String 建表语句
    /// @throws SQLException 当获取失败时抛出异常
    public String getCreateTableStatement(String connectionId, String database, String table) throws SQLException {
        Connection connection = connections.get(connectionId);
        if (connection == null) {
            throw new IllegalStateException("Connection not found");
        }

        connection.setCatalog(database);
        try (Statement stmt = connection.createStatement();
             ResultSet rs = stmt.executeQuery("SHOW CREATE TABLE `" + table + "`")) {
            if (rs.next()) {
                return rs.getString(2); // 建表语句在第二列
            }
            throw new SQLException("Failed to get create table statement");
        }
    }
} 