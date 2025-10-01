# Build stage
FROM dart:stable AS build

WORKDIR /app

# Copy ALL files (Railway build context includes everything)
COPY . .

# Change to backend directory and build there
WORKDIR /app/backend

RUN dart pub get
RUN dart compile exe bin/server.dart -o /app/server

# Runtime stage
FROM debian:bullseye-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy compiled app from build stage
COPY --from=build /app/server /app/server

# Expose port (Railway uses PORT env var)
EXPOSE 8080

# Run server
CMD ["/app/server"]

