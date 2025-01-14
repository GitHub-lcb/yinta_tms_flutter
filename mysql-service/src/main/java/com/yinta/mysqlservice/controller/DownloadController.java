package com.yinta.mysqlservice.controller;

import com.yinta.mysqlservice.service.DownloadService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import lombok.extern.slf4j.Slf4j;

import javax.annotation.Resource;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api")
public class DownloadController {

    @Resource
    private DownloadService downloadService;

    @GetMapping("/downloads")
    public ResponseEntity<Map<String, String>> getDownloadUrls() {
        log.info("Fetching download URLs");
        Map<String, String> urls = downloadService.getDownloadUrls();
        log.debug("Download URLs: {}", urls);
        return ResponseEntity.ok(urls);
    }
} 