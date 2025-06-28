# First stage: Build all
ARG IMAGE=ubuntu:24.04
FROM $IMAGE AS build

# Install build tools and dependencies
RUN apt-get update && apt-get install -y \
  git libconfig-dev uthash-dev build-essential \
  libssl-dev automake autoconf libreadline-dev \
  gawk libsnmp-dev libtool tcpdump iproute2 iputils-ping

# Setup build environment
RUN mkdir -p /build/installroot
WORKDIR /build

# Clone your fork of NIST-BGP-SRx
RUN git clone https://github.com/marijnvalks/NIST-BGP-SRx.git

# Build srx-crypto-api
RUN cd NIST-BGP-SRx/srx-crypto-api && \
    autoreconf -i && \
    ./configure CFLAGS="-O0 -g" && \
    make && \
    make install && \
    make install DESTDIR=/build/installroot && \
    ln -s /usr/local/lib/libSRxCryptoAPI.so /usr/local/lib/libSRxCryptoAPI.so.3 && \
    ldconfig

# Build bgpsec-io
RUN cd NIST-BGP-SRx/bgpsec-io && \
    autoreconf -i && \
    ./configure sca_dir="/usr/local" && \
    make && \
    make install && \
    make install DESTDIR=/build/installroot

# Second stage: runtime only
FROM $IMAGE AS deploy

# Install runtime dependencies
RUN apt-get update && \
    apt-get -y dist-upgrade && \
    apt-get install -y --no-install-recommends libconfig-dev libltdl-dev tcpdump iproute2 iputils-ping && \
    apt-get clean

# Copy installed binaries and libs
COPY --from=build /build/installroot/usr/local/ /usr/local/

# Set runtime linker path
ENV LD_LIBRARY_PATH=/usr/local/lib

# Optional: symlink for bgpsec-io naming consistency
RUN ln -s /usr/local/bin/bgpsecio /usr/local/bin/bgpsec-io

CMD ["/bin/bash"]