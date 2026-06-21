package com.spraymate.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.spraymate.dto.WeatherResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service
public class WeatherService {

    @Value("${openweather.api.key}")
    private String apiKey;

    @Value("${openweather.api.url}")
    private String apiUrl;

    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

    public WeatherResponse checkConditions(double lat, double lon) {
        String url = String.format("%s?lat=%f&lon=%f&appid=%s&units=metric", apiUrl, lat, lon, apiKey);

        String json = restTemplate.getForObject(url, String.class);

        try {
            JsonNode root = objectMapper.readTree(json);
            JsonNode wind = root.path("wind");
            JsonNode main = root.path("main");

            // Wind speed from m/s to mph
            double windSpeedMs = wind.path("speed").asDouble();
            double windSpeedMph = windSpeedMs * 2.237;

            double temperature = main.path("temp").asDouble();
            int humidity = main.path("humidity").asInt();

            return evaluateConditions(windSpeedMph, temperature, humidity);
        } catch (Exception e) {
            throw new RuntimeException("Failed to parse weather data: " + e.getMessage());
        }
    }

    private WeatherResponse evaluateConditions(double windSpeed, double temperature, int humidity) {
        WeatherResponse response = new WeatherResponse();
        response.setWindSpeed(Math.round(windSpeed * 10.0) / 10.0);
        response.setTemperature(Math.round(temperature * 10.0) / 10.0);
        response.setHumidity(humidity);

        // Evaluate wind
        boolean windNoGo = windSpeed > 12;
        boolean windModerate = windSpeed >= 8 && windSpeed <= 12;
        boolean windGood = windSpeed < 8;

        if (windNoGo) {
            response.setWindStatus("Too High");
        } else if (windModerate) {
            response.setWindStatus("Moderate");
        } else {
            response.setWindStatus("Good");
        }

        // Evaluate temperature
        boolean tempNoGo = temperature < 5 || temperature > 40;
        boolean tempModerate = (temperature >= 5 && temperature < 10) || (temperature > 35 && temperature <= 40);
        boolean tempGood = temperature >= 10 && temperature <= 35;

        if (tempNoGo) {
            response.setTempStatus("Too High");
        } else if (tempModerate) {
            response.setTempStatus("Moderate");
        } else {
            response.setTempStatus("Good");
        }

        // Evaluate humidity
        boolean humidityNoGo = humidity > 90;
        boolean humidityModerate = (humidity > 80 && humidity <= 90) || humidity < 40;
        boolean humidityGood = humidity >= 40 && humidity <= 80;

        if (humidityNoGo) {
            response.setHumidityStatus("Too High");
        } else if (humidityModerate) {
            response.setHumidityStatus("Moderate");
        } else {
            response.setHumidityStatus("Good");
        }

        // Calculate Delta T
        double wetBulb = calculateWetBulbTemperature(temperature, humidity);
        double deltaT = Math.round((temperature - wetBulb) * 10.0) / 10.0;
        response.setWetBulbTemperature(Math.round(wetBulb * 10.0) / 10.0);
        response.setDeltaT(deltaT);

        // Evaluate Delta T
        // Ideal: 2-8°C, Moderate: 8-10°C, No-Go: >10 or <2
        boolean deltaTNoGo = deltaT > 10 || deltaT < 2;
        boolean deltaTModerate = (deltaT >= 8 && deltaT <= 10);
        boolean deltaTGood = deltaT >= 2 && deltaT < 8;

        if (deltaT > 10) {
            response.setDeltaTStatus("Too High");
        } else if (deltaT < 2) {
            response.setDeltaTStatus("Too Low");
        } else if (deltaTModerate) {
            response.setDeltaTStatus("Moderate");
        } else {
            response.setDeltaTStatus("Good");
        }

        // Overall status: worst factor wins (now including Delta T)
        if (windNoGo || tempNoGo || humidityNoGo || deltaTNoGo) {
            response.setStatus("NO_GO");
            response.setMessage("Conditions are not safe for spraying. Please wait for better conditions.");
        } else if (windModerate || tempModerate || humidityModerate || deltaTModerate) {
            response.setStatus("MODERATE");
            response.setMessage("Conditions are moderate. Exercise caution and follow safety guidelines.");
        } else {
            response.setStatus("GO");
            response.setMessage("Conditions are safe for spraying.");
        }

        return response;
    }

    /**
     * Calculates wet-bulb temperature using the Stull (2011) approximation.
     * Valid for RH 5-99% and temperature -20°C to 50°C.
     * Accuracy: mean absolute error < 0.3°C.
     *
     * @param temperature Dry-bulb temperature in °C
     * @param humidity    Relative humidity in % (0-100)
     * @return Wet-bulb temperature in °C
     */
    private double calculateWetBulbTemperature(double temperature, int humidity) {
        double rh = humidity;
        double tw = temperature * Math.atan(0.151977 * Math.sqrt(rh + 8.313659))
                + Math.atan(temperature + rh)
                - Math.atan(rh - 1.676331)
                + 0.00391838 * Math.pow(rh, 1.5) * Math.atan(0.023101 * rh)
                - 4.686035;
        return tw;
    }
}
