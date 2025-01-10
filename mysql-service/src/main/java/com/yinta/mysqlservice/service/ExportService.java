package com.yinta.mysqlservice.service;

import com.opencsv.CSVWriter;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.io.StringWriter;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class ExportService {
    private final DatabaseService databaseService;

    public byte[] exportToExcel(String connectionId, String query) throws Exception {
        List<Map<String, Object>> data = databaseService.executeQuery(connectionId, query);
        if (data.isEmpty()) {
            throw new IllegalStateException("No data to export");
        }

        try (Workbook workbook = new XSSFWorkbook()) {
            Sheet sheet = workbook.createSheet("Data");

            // Create header style
            CellStyle headerStyle = workbook.createCellStyle();
            headerStyle.setFillForegroundColor(IndexedColors.GREY_25_PERCENT.getIndex());
            headerStyle.setFillPattern(FillPatternType.SOLID_FOREGROUND);
            Font headerFont = workbook.createFont();
            headerFont.setBold(true);
            headerStyle.setFont(headerFont);

            // Create headers
            Row headerRow = sheet.createRow(0);
            List<String> columns = new ArrayList<>(data.get(0).keySet());
            for (int i = 0; i < columns.size(); i++) {
                Cell cell = headerRow.createCell(i);
                cell.setCellValue(columns.get(i));
                cell.setCellStyle(headerStyle);
                sheet.autoSizeColumn(i);
            }

            // Create data rows
            for (int i = 0; i < data.size(); i++) {
                Row row = sheet.createRow(i + 1);
                Map<String, Object> rowData = data.get(i);
                for (int j = 0; j < columns.size(); j++) {
                    Cell cell = row.createCell(j);
                    Object value = rowData.get(columns.get(j));
                    if (value != null) {
                        cell.setCellValue(value.toString());
                    }
                }
            }

            // Auto-size columns
            for (int i = 0; i < columns.size(); i++) {
                sheet.autoSizeColumn(i);
            }

            ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
            workbook.write(outputStream);
            return outputStream.toByteArray();
        }
    }

    public String exportToCsv(String connectionId, String query) throws Exception {
        List<Map<String, Object>> data = databaseService.executeQuery(connectionId, query);
        if (data.isEmpty()) {
            throw new IllegalStateException("No data to export");
        }

        StringWriter stringWriter = new StringWriter();
        try (CSVWriter csvWriter = new CSVWriter(stringWriter)) {
            // Write headers
            List<String> columns = new ArrayList<>(data.get(0).keySet());
            csvWriter.writeNext(columns.toArray(new String[0]));

            // Write data
            for (Map<String, Object> row : data) {
                String[] rowData = new String[columns.size()];
                for (int i = 0; i < columns.size(); i++) {
                    Object value = row.get(columns.get(i));
                    rowData[i] = value != null ? value.toString() : "";
                }
                csvWriter.writeNext(rowData);
            }
        }

        return stringWriter.toString();
    }
} 