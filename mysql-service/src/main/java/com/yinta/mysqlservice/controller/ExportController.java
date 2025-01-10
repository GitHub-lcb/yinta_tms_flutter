package com.yinta.mysqlservice.controller;

import com.yinta.mysqlservice.service.ExportService;
import com.yinta.mysqlservice.service.JwtService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/export")
@RequiredArgsConstructor
@CrossOrigin
public class ExportController {
    private final ExportService exportService;
    private final JwtService jwtService;

    @PostMapping("/excel")
    public ResponseEntity<byte[]> exportToExcel(
            @RequestHeader("Authorization") String authHeader,
            @RequestBody Map<String, String> request) {
        try {
            String token = authHeader.substring(7);
            String connectionId = jwtService.getConnectionIdFromToken(token);
            String query = request.get("query");
            String filename = request.get("filename");

            if (query == null || query.trim().isEmpty()) {
                throw new IllegalArgumentException("Query cannot be empty");
            }

            if (filename == null || filename.trim().isEmpty()) {
                filename = "export.xlsx";
            } else if (!filename.endsWith(".xlsx")) {
                filename += ".xlsx";
            }

            byte[] excelFile = exportService.exportToExcel(connectionId, query);
            String encodedFilename = URLEncoder.encode(filename, StandardCharsets.UTF_8.toString())
                    .replace("+", "%20");

            return ResponseEntity.ok()
                    .contentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename*=UTF-8''" + encodedFilename)
                    .body(excelFile);
        } catch (Exception e) {
            log.error("Error exporting to Excel", e);
            return ResponseEntity.internalServerError().build();
        }
    }

    @PostMapping("/csv")
    public ResponseEntity<String> exportToCsv(
            @RequestHeader("Authorization") String authHeader,
            @RequestBody Map<String, String> request) {
        try {
            String token = authHeader.substring(7);
            String connectionId = jwtService.getConnectionIdFromToken(token);
            String query = request.get("query");
            String filename = request.get("filename");

            if (query == null || query.trim().isEmpty()) {
                throw new IllegalArgumentException("Query cannot be empty");
            }

            if (filename == null || filename.trim().isEmpty()) {
                filename = "export.csv";
            } else if (!filename.endsWith(".csv")) {
                filename += ".csv";
            }

            String csvContent = exportService.exportToCsv(connectionId, query);
            String encodedFilename = URLEncoder.encode(filename, StandardCharsets.UTF_8.toString())
                    .replace("+", "%20");

            return ResponseEntity.ok()
                    .contentType(MediaType.parseMediaType("text/csv"))
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename*=UTF-8''" + encodedFilename)
                    .body(csvContent);
        } catch (Exception e) {
            log.error("Error exporting to CSV", e);
            return ResponseEntity.internalServerError().build();
        }
    }
} 