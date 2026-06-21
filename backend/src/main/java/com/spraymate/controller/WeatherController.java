package com.spraymate.controller;

import com.spraymate.dto.WeatherResponse;
import com.spraymate.service.WeatherService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/weather")
@CrossOrigin(origins = "*")
public class WeatherController {

    private final WeatherService weatherService;

    public WeatherController(WeatherService weatherService) {
        this.weatherService = weatherService;
    }

    @GetMapping("/check")
    public ResponseEntity<?> checkConditions(
            @RequestParam double lat,
            @RequestParam double lon) {
        try {
            WeatherResponse response = weatherService.checkConditions(lat, lon);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.internalServerError()
                    .body(Map.of("error", "Failed to check weather: " + e.getMessage()));
        }
    }
}
