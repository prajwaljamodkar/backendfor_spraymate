package com.spraymate.dto;

public class ProfileResponse {
    private String email;
    private String name;
    private String message;

    public ProfileResponse() {}

    public ProfileResponse(String email, String name, String message) {
        this.email = email;
        this.name = name;
        this.message = message;
    }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }
}
