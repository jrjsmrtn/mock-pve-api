# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

# Multi-stage build for Mock PVE API Server
FROM elixir:1.15-alpine AS builder

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    git \
    curl

# Set working directory
WORKDIR /app

# Copy mix files first (for better layer caching)
COPY mix.exs mix.lock ./

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set environment for dependencies
ENV MIX_ENV=prod

# Install dependencies
RUN mix deps.get --only prod && \
    mix deps.compile

# Copy source code
COPY config ./config
COPY lib ./lib

# Remove test_helper from production build
RUN rm -f lib/mock_pve_api/test_helper.ex

# Compile the application
RUN mix compile

# Build release
RUN mix release

# ---- Runtime Stage ----
FROM alpine:3.18 AS runtime

# Install runtime dependencies
RUN apk add --no-cache \
    bash \
    openssl \
    ncurses-libs \
    libstdc++ \
    curl

# Create app user
RUN addgroup -g 1000 mockpve && \
    adduser -u 1000 -G mockpve -s /bin/bash -D mockpve

# Set working directory
WORKDIR /app

# Copy release from builder stage
COPY --from=builder --chown=mockpve:mockpve /app/_build/prod/rel/mock_pve_api .

# Copy certificate generation script
COPY --chown=mockpve:mockpve scripts/generate-certs.sh ./scripts/

# Create certificate directory with proper permissions
RUN mkdir -p certs && chown mockpve:mockpve certs

# Switch to app user
USER mockpve

# Expose PVE API port
EXPOSE 8006

# Health check (supports both HTTP and HTTPS)
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD if [ "$MOCK_PVE_SSL_ENABLED" = "true" ]; then \
            curl -fk https://localhost:8006/api2/json/version || exit 1; \
        else \
            curl -f http://localhost:8006/api2/json/version || exit 1; \
        fi

# Set environment variables
ENV MOCK_PVE_PORT=8006
ENV MOCK_PVE_HOST=0.0.0.0
ENV MOCK_PVE_VERSION=8.3
ENV MOCK_PVE_SSL_ENABLED=false
ENV MOCK_PVE_SSL_KEYFILE=certs/server.key
ENV MOCK_PVE_SSL_CERTFILE=certs/server.crt

# Start the server
CMD ["./bin/mock_pve_api", "start"]