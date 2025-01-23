package com.yinta.mysqlservice.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import lombok.extern.slf4j.Slf4j;

import java.util.HashMap;
import java.util.Map;

@Slf4j
@Service
public class DownloadService {

    @Value("${app.download.base-url}")
    private String baseUrl;

    @Value("${app.version}")
    private String version;

    public Map<String, String> getDownloadUrls() {
        log.info("Generating download URLs with base URL: {} and version: {}", baseUrl, version);
        Map<String, String> urls = new HashMap<>();
        
        try {
            // 添加版本信息
            urls.put("currentVersion", version);
            
            // Web版本
            urls.put("web", "https://yintademo.lichenbo.cn");
            
            // 桌面版本
            urls.put("windows", "https://qny.lichenbo.cn/tms/tms-connect.exe");
            urls.put("macos", "");
            urls.put("linux", String.format("%s/desktop/linux/mysql-client-%s.AppImage", baseUrl, version));
            
            // 移动版本
            urls.put("android", "https://qny.lichenbo.cn/tms/tms-connect.apk");
            urls.put("ios", "");
            
            log.debug("Generated download URLs: {}", urls);
            return urls;
        } catch (Exception e) {
            log.error("Error generating download URLs", e);
            throw new RuntimeException("Failed to generate download URLs", e);
        }
    }
} 