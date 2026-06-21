package com.spraymate.dto;

public class WeatherResponse {
    private String status;       // "GO", "MODERATE", "NO_GO"
    private String message;
    private double windSpeed;    // in mph
    private double temperature;  // in Celsius
    private int humidity;        // percentage
    private String windStatus;   // "Good", "Moderate", "Too High"
    private String tempStatus;
    private String humidityStatus;
    private double deltaT;              // Delta T value in °C
    private String deltaTStatus;        // "Good", "Moderate", "Too High", "Too Low"
    private double wetBulbTemperature;  // Wet bulb temperature in °C

    public WeatherResponse() {}

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }

    public double getWindSpeed() { return windSpeed; }
    public void setWindSpeed(double windSpeed) { this.windSpeed = windSpeed; }

    public double getTemperature() { return temperature; }
    public void setTemperature(double temperature) { this.temperature = temperature; }

    public int getHumidity() { return humidity; }
    public void setHumidity(int humidity) { this.humidity = humidity; }

    public String getWindStatus() { return windStatus; }
    public void setWindStatus(String windStatus) { this.windStatus = windStatus; }

    public String getTempStatus() { return tempStatus; }
    public void setTempStatus(String tempStatus) { this.tempStatus = tempStatus; }

    public String getHumidityStatus() { return humidityStatus; }
    public void setHumidityStatus(String humidityStatus) { this.humidityStatus = humidityStatus; }

    public double getDeltaT() { return deltaT; }
    public void setDeltaT(double deltaT) { this.deltaT = deltaT; }

    public String getDeltaTStatus() { return deltaTStatus; }
    public void setDeltaTStatus(String deltaTStatus) { this.deltaTStatus = deltaTStatus; }

    public double getWetBulbTemperature() { return wetBulbTemperature; }
    public void setWetBulbTemperature(double wetBulbTemperature) { this.wetBulbTemperature = wetBulbTemperature; }
}
