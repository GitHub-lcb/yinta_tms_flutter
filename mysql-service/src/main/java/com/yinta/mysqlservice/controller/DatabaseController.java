package com.yinta.mysqlservice.controller;

import com.yinta.mysqlservice.config.DatabaseConfig;
import com.yinta.mysqlservice.service.DatabaseService;
import com.yinta.mysqlservice.service.JwtService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.sql.Connection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping(value = "/api", produces = MediaType.APPLICATION_JSON_VALUE)
@RequiredArgsConstructor
@CrossOrigin
public class DatabaseController {

    private final DatabaseService databaseService;
    private final JwtService jwtService;

    @PostMapping("/connect")
    public ResponseEntity<?> connect(@RequestBody DatabaseConfig config) {
        try {
            log.info("Attempting to connect to database: {}:{}", config.getHost(), config.getPort());
            String connectionId = databaseService.connect(config);
            String token = jwtService.generateToken(connectionId);
            
            Map<String, String> response = new HashMap<>();
            response.put("token", token);
            
            log.info("Connection successful, token generated: {}", token);
            return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_JSON)
                .body(response);
        } catch (Exception e) {
            log.error("Connection failed", e);
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .contentType(MediaType.APPLICATION_JSON)
                .body(errorResponse);
        }
    }

    @PostMapping("/disconnect")
    public ResponseEntity<?> disconnect(@RequestHeader("Authorization") String authHeader) {
        try {
            String token = authHeader.substring(7); // Remove "Bearer "
            String connectionId = jwtService.getConnectionIdFromToken(token);
            databaseService.disconnect(connectionId);
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @GetMapping("/databases")
    public ResponseEntity<?> getDatabases(@RequestHeader("Authorization") String authHeader) {
        try {
            String token = authHeader.substring(7);
            String connectionId = jwtService.getConnectionIdFromToken(token);
            List<String> databases = databaseService.getDatabases(connectionId);
            return ResponseEntity.ok(databases);
        } catch (Exception e) {
            log.error("Error getting databases", e);
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(errorResponse);
        }
    }

    @GetMapping("/tables")
    public ResponseEntity<?> getTables(
            @RequestHeader("Authorization") String authHeader,
            @RequestParam String database) {
        try {
            log.info("Getting tables for database: {}", database);
            String token = authHeader.substring(7);
            String connectionId = jwtService.getConnectionIdFromToken(token);
            log.info("Connection ID: {}", connectionId);
            
            List<String> tables = databaseService.getTables(connectionId, database);
            log.info("Found {} tables", tables.size());
            return ResponseEntity.ok(tables);
        } catch (Exception e) {
            log.error("Error getting tables for database: " + database, e);
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(errorResponse);
        }
    }

    @PostMapping("/query")
    public ResponseEntity<?> executeQuery(
            @RequestHeader("Authorization") String authHeader,
            @RequestBody Map<String, String> request) {
        try {
            String token = authHeader.substring(7);
            String connectionId = jwtService.getConnectionIdFromToken(token);
            String query = request.get("query");
            
            if (query == null || query.trim().isEmpty()) {
                throw new IllegalArgumentException("Query cannot be empty");
            }

            log.info("Executing query: {}", query);
            List<Map<String, Object>> results = databaseService.executeQuery(connectionId, query);
            log.info("Query executed successfully, returned {} rows", results.size());
            
            Map<String, Object> response = new HashMap<>();
            response.put("results", results);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Error executing query", e);
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(errorResponse);
        }
    }

    @PostMapping("/select-database")
    public ResponseEntity<Map<String, String>> selectDatabase(
            @RequestHeader("Authorization") String token,
            @RequestBody Map<String, String> request) {
        try {
            String connectionId = jwtService.getConnectionIdFromToken(token.replace("Bearer ", ""));
            String database = request.get("database");
            if (database == null || database.isEmpty()) {
                throw new IllegalArgumentException("Database name is required");
            }
            databaseService.selectDatabase(connectionId, database);
            Map<String, String> response = new HashMap<>();
            response.put("message", "Database selected successfully");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Error selecting database", e);
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(errorResponse);
        }
    }

    @GetMapping("/table-structure")
    public ResponseEntity<?> getTableStructure(
            @RequestHeader("Authorization") String authHeader,
            @RequestParam String database,
            @RequestParam String table) {
        try {
            String token = authHeader.substring(7);
            String connectionId = jwtService.getConnectionIdFromToken(token);
            List<Map<String, Object>> structure = databaseService.getTableStructure(connectionId, database, table);
            return ResponseEntity.ok(structure);
        } catch (Exception e) {
            log.error("Error getting table structure", e);
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(errorResponse);
        }
    }

    @GetMapping("/table-indexes")
    public ResponseEntity<?> getTableIndexes(
            @RequestHeader("Authorization") String authHeader,
            @RequestParam String database,
            @RequestParam String table) {
        try {
            String token = authHeader.substring(7);
            String connectionId = jwtService.getConnectionIdFromToken(token);
            List<Map<String, Object>> indexes = databaseService.getTableIndexes(connectionId, database, table);
            return ResponseEntity.ok(indexes);
        } catch (Exception e) {
            log.error("Error getting table indexes", e);
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(errorResponse);
        }
    }

    @PostMapping("/alter-table")
    public ResponseEntity<?> alterTable(
            @RequestHeader("Authorization") String authHeader,
            @RequestBody Map<String, Object> request) {
        try {
            String token = authHeader.substring(7);
            String connectionId = jwtService.getConnectionIdFromToken(token);
            String database = (String) request.get("database");
            String table = (String) request.get("table");
            String alterSql = (String) request.get("alterSql");
            
            databaseService.alterTable(connectionId, database, table, alterSql);
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            log.error("Error altering table", e);
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(errorResponse);
        }
    }
} 