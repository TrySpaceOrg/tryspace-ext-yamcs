# Multi-stage build for TrySpace GSW (YAMCS)
FROM maven:3.9.9-eclipse-temurin-17 AS builder

WORKDIR /app

# Copy Maven files for dependency resolution
COPY pom.xml ./
COPY mvnw mvnw.cmd ./
COPY .mvn .mvn/

# Download dependencies
RUN mvn dependency:go-offline -B

# Copy source code
COPY src/ src/

# Build the application
RUN mvn clean package -DskipTests

# Production stage
FROM eclipse-temurin:17-jre-jammy

WORKDIR /app

# Install curl for healthcheck
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Copy the built application from builder stage
COPY --from=builder /app/target/*-bundle.tar.gz ./
RUN tar -xzf *-bundle.tar.gz --strip-components=1 && rm *-bundle.tar.gz

# Create user for development (matches host user)
ARG USER_ID=1000
ARG GROUP_ID=1000
RUN groupadd -g ${GROUP_ID} developer && \
    useradd -u ${USER_ID} -g ${GROUP_ID} -m -s /bin/bash tryspace && \
    mkdir -p /app/yamcs-data && \
    chown -R tryspace:developer /app

USER tryspace

# Expose ports
EXPOSE 8090 10015/udp 10025/udp

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8090 || exit 1

# Start YAMCS
CMD ["./bin/yamcsd"]
