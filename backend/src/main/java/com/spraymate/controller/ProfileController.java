package com.spraymate.controller;

import com.spraymate.dto.ProfileResponse;
import com.spraymate.dto.ProfileUpdateRequest;
import com.spraymate.model.User;
import com.spraymate.repository.UserRepository;
import com.spraymate.util.JwtUtil;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/profile")
@CrossOrigin(origins = "*")
public class ProfileController {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    public ProfileController(UserRepository userRepository, PasswordEncoder passwordEncoder, JwtUtil jwtUtil) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtUtil = jwtUtil;
    }

    @GetMapping
    public ResponseEntity<?> getProfile(@RequestHeader("Authorization") String authHeader) {
        try {
            String email = extractEmailFromToken(authHeader);
            User user = userRepository.findByEmail(email)
                    .orElseThrow(() -> new RuntimeException("User not found"));

            return ResponseEntity.ok(new ProfileResponse(user.getEmail(), user.getName(), "Profile loaded"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PutMapping
    public ResponseEntity<?> updateProfile(
            @RequestHeader("Authorization") String authHeader,
            @RequestBody ProfileUpdateRequest request) {
        try {
            String email = extractEmailFromToken(authHeader);
            User user = userRepository.findByEmail(email)
                    .orElseThrow(() -> new RuntimeException("User not found"));

            // Update name if provided
            if (request.getName() != null && !request.getName().trim().isEmpty()) {
                user.setName(request.getName().trim());
            }

            // Update email if provided and different
            if (request.getEmail() != null && !request.getEmail().trim().isEmpty()
                    && !request.getEmail().trim().equals(user.getEmail())) {
                if (userRepository.existsByEmail(request.getEmail().trim())) {
                    throw new RuntimeException("Email already in use by another account");
                }
                user.setEmail(request.getEmail().trim());
            }

            // Update password if provided
            if (request.getNewPassword() != null && !request.getNewPassword().isEmpty()) {
                if (request.getCurrentPassword() == null || request.getCurrentPassword().isEmpty()) {
                    throw new RuntimeException("Current password is required to change password");
                }
                if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPassword())) {
                    throw new RuntimeException("Current password is incorrect");
                }
                user.setPassword(passwordEncoder.encode(request.getNewPassword()));
            }

            userRepository.save(user);

            // Generate new token with potentially updated email
            String newToken = jwtUtil.generateToken(user.getEmail());

            Map<String, Object> responseBody = Map.of(
                    "email", user.getEmail(),
                    "name", user.getName(),
                    "token", newToken,
                    "message", "Profile updated successfully"
            );

            return ResponseEntity.ok(responseBody);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    private String extractEmailFromToken(String authHeader) {
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            throw new RuntimeException("Invalid authorization header");
        }
        String token = authHeader.substring(7);
        if (!jwtUtil.validateToken(token)) {
            throw new RuntimeException("Invalid or expired token");
        }
        return jwtUtil.extractEmail(token);
    }
}
