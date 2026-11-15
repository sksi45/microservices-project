
# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0
# http://www.apache.org/licenses/LICENSE-2.0

# ==========================================
# STAGE 1: BUILD APPLICATION
# ==========================================
FROM eclipse-temurin:19@sha256:f3fbf1ad599d4b5dbdd7ceb55708d10cb9fafb08e094ef91e92aa63b520a232e AS builder

WORKDIR /app

COPY ["build.gradle", "gradlew", "./"]
COPY gradle gradle

RUN chmod +x gradlew
RUN ./gradlew downloadRepos

COPY . .

RUN chmod +x gradlew
RUN ./gradlew installDist

# ==========================================
# STAGE 2: RUNTIME BASE
# ==========================================
FROM eclipse-temurin:19.0.1_10-jre-alpine@sha256:a75ea64f676041562cd7d3a54a9764bbfb357b2bf1bebf46e2af73e62d32e36c AS runtime-base

RUN apk add --no-cache ca-certificates wget

# Download Stackdriver Profiler Java agent
RUN mkdir -p /opt/cprof && \
    wget -q -O- \
    https://storage.googleapis.com/cloud-profiler/java/latest/profiler_java_agent_alpine.tar.gz \
    | tar xz -C /opt/cprof

WORKDIR /app

COPY --from=builder /app .

EXPOSE 9555

ENTRYPOINT ["/app/build/install/hipstershop/bin/AdService"]

# ==========================================
# STAGE 3: FINAL IMAGE WITH GRPC HEALTH PROBE
# ==========================================
FROM runtime-base AS final

ENV GRPC_HEALTH_PROBE_VERSION=v0.4.18

RUN wget -qO /bin/grpc_health_probe \
    https://github.com/grpc-ecosystem/grpc-health-probe/releases/download/${GRPC_HEALTH_PROBE_VERSION}/grpc_health_probe-linux-amd64 \
    && chmod 0755 /bin/grpc_health_probe \
    && test -x /bin/grpc_health_probe

