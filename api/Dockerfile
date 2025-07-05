# syntax=docker/dockerfile:1

########################
# Build stage          #
########################
FROM golang:1.24-alpine AS builder

# Instal dependencies for building (none needed beyond base alpine)
WORKDIR /app

# Copy go modules manifests and download deps first for better caching
COPY go.mod go.sum ./
RUN go mod download

# Copy the rest of the source code
COPY . .

# Build the binary statically
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o cocktails-api ./

########################
# Runtime stage        #
########################
FROM gcr.io/distroless/static-debian12 AS runtime

WORKDIR /app
COPY --from=builder /app/cocktails-api /cocktails-api

# Application listens on 8080 by default
EXPOSE 8080

ENTRYPOINT ["/cocktails-api"] 