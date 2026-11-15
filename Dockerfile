
# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0
# You may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM python:3.10-slim-bookworm AS base

FROM base AS builder

RUN apt-get -qq update \
    && apt-get install -y --no-install-recommends \
        wget g++ \
    && rm -rf /var/lib/apt/lists/*

# Download the gRPC health probe
ENV GRPC_HEALTH_PROBE_VERSION=v0.4.18

RUN wget -qO/bin/grpc_health_probe \
    https://github.com/grpc-ecosystem/grpc-health-probe/releases/download/${GRPC_HEALTH_PROBE_VERSION}/grpc_health_probe-linux-amd64 \
    && chmod +x /bin/grpc_health_probe

# Install Python packages
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM base AS without-grpc-health-probe-bin

ENV PYTHONUNBUFFERED=1

WORKDIR /recommendationservice

# Copy installed packages
COPY --from=builder /usr/local/lib/python3.10/ /usr/local/lib/python3.10/

# Copy application files
COPY . .

ENV PORT=8080

EXPOSE 8080

ENTRYPOINT ["python", "recommendation_server.py"]

FROM without-grpc-health-probe-bin

COPY --from=builder /bin/grpc_health_probe /bin/grpc_health_probe
