# Build stage
FROM dart:stable AS build

WORKDIR /app

# Copy backend files
COPY backend/pubspec.* ./
RUN dart pub get

# Copy source code
COPY backend/ ./

# Compile
RUN dart compile exe bin/server.dart -o bin/server

# Runtime stage
FROM debian:bullseye-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy compiled app
COPY --from=build /app/bin/server /app/bin/

# Expose port
EXPOSE 8080

# Run server
CMD ["/app/bin/server"]

