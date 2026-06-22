# ── Stage 1: Build ──────────────────────────────────────────
FROM eclipse-temurin:17-jdk-alpine AS build

WORKDIR /app

# Copy Maven wrapper and pom first for dependency caching
COPY pom.xml .
COPY .mvn .mvn
COPY mvnw .
RUN chmod +x mvnw

# Download dependencies (cached layer unless pom.xml changes)
RUN ./mvnw dependency:resolve -B

# Copy source code and build
COPY src ./src
RUN ./mvnw package -DskipTests -B

# ── Stage 2: Runtime ───────────────────────────────────────
FROM eclipse-temurin:17-jre-alpine AS runtime

WORKDIR /app

# Create a non-root user for security
RUN addgroup -S spraymate && adduser -S spraymate -G spraymate

# Copy the built JAR from the build stage
COPY --from=build /app/target/*.jar app.jar

# Set ownership
RUN chown -R spraymate:spraymate /app
USER spraymate

# Expose port (Render injects PORT env var)
EXPOSE 8080

# JVM tuning for containerized environments
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -Djava.security.egd=file:/dev/./urandom"
ENV SPRING_PROFILES_ACTIVE=render

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
