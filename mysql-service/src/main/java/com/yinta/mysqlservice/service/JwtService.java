package com.yinta.mysqlservice.service;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import org.springframework.stereotype.Service;

import java.util.Date;
import java.util.HashMap;
import java.util.Map;

@Service
public class JwtService {
    private static final String SECRET_KEY = "yintaTmsFlutterSecretKeyForJwtTokenGenerationAndValidation2024";
    private static final long EXPIRATION_TIME = 24 * 60 * 60 * 1000; // 24 hours

    public String generateToken(String connectionId) {
        Map<String, Object> claims = new HashMap<>();
        claims.put("connectionId", connectionId);
        return Jwts.builder()
                .setClaims(claims)
                .setSubject(connectionId)
                .setIssuedAt(new Date(System.currentTimeMillis()))
                .setExpiration(new Date(System.currentTimeMillis() + EXPIRATION_TIME))
                .signWith(SignatureAlgorithm.HS256, SECRET_KEY.getBytes())
                .compact();
    }

    public String getConnectionIdFromToken(String token) {
        Claims claims = extractAllClaims(token);
        return claims.get("connectionId", String.class);
    }

    private Claims extractAllClaims(String token) {
        return Jwts.parser()
                .setSigningKey(SECRET_KEY.getBytes())
                .parseClaimsJws(token)
                .getBody();
    }

    public boolean isTokenExpired(String token) {
        return extractAllClaims(token)
                .getExpiration()
                .before(new Date());
    }
} 