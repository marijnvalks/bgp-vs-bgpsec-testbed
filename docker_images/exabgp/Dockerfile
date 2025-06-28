# ---------- Stage 1: Builder ----------
ARG IMAGE=ubuntu:24.04
FROM $IMAGE AS build

# Install build-time dependencies
RUN apt-get update && apt-get install -y \
    git python3 python3-pip

# Clone ExaBGP source
WORKDIR /build
RUN git clone https://github.com/Exa-Networks/exabgp.git

# Install into build root
RUN pip install --break-system-packages /build/exabgp


# ---------- Stage 2: Runtime ----------
FROM $IMAGE AS deploy

# Install runtime dependencies only
RUN apt-get update && apt-get install -y \
    python3 python3-pip bash iproute2 iputils-ping net-tools && \
    apt-get clean

# Install ExaBGP from the built wheel/cache
COPY --from=build /usr/local /usr/local

# Keep container alive by default
CMD ["bash", "-c", "while true; do sleep 3600; done"]
