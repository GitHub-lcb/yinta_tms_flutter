package com.yinta.mysqlservice.config;

import lombok.Data;
import org.springframework.context.annotation.Configuration;

@Data
public class DatabaseConfig {
    private String host;
    private int port;
    private String username;
    private String password;
    private String database;
} 