# Copyright (c) 2025 SIDN Labs
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from
#    this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# First stage: Build quaggasrx and srx-crypto-api
ARG IMAGE=ubuntu:24.04
FROM $IMAGE AS build

# install required packages
RUN apt-get update && apt-get install -y git libconfig-dev uthash-dev build-essential libssl-dev automake autoconf libreadline-dev gawk libsnmp-dev libtool libncurses-dev libltdl-dev iproute2 iputils-ping tcpdump

# Setup build environment
RUN mkdir -p /build/installroot
WORKDIR "/build/"

# NIST-BGP-SRx source code
RUN git clone https://github.com/usnistgov/NIST-BGP-SRx.git

# install srx-crypto-api
RUN cd NIST-BGP-SRx/srx-crypto-api && \
    autoreconf -i && \
    ./configure CFLAGS="-O0 -g" && \
    make && \
    # install for compilation of quaggasrx
    make install && \
    # install for use in second stage
    make install DESTDIR=/build/installroot

# install srx-server
RUN cd NIST-BGP-SRx/srx-server && \
    autoreconf -i && \
    ./configure sca_dir="/usr/local" && \
    make && \
    # install for compilation of quaggasrx
    make install && \
    # install for use in second stage
    make install DESTDIR=/build/installroot

# install quaggasrx
RUN cd NIST-BGP-SRx/quagga-srx && \
    autoreconf -i && \
    ./configure  --enable-vtysh --disable-ospfapi --disable-ospfd --disable-ospf6d --disable-babeld --disable-doc --enable-user=root --enable-group=root --enable-configfile-mask=0644 --enable-logfile-mask=0644 --enable-srxcryptoapi sca_dir="/usr/local" srx_dir="/usr/local" && \
    make -j && \
    make install DESTDIR=/build/installroot



RUN cd /build/installroot && tar -cf /build/artifact.tar -C /build/installroot . 




# Second stage: only required binaries, configs and scripts
FROM $IMAGE AS deploy

# Install dependencies
RUN apt-get update && \
    apt-get -y dist-upgrade && \
    apt-get install -y --no-install-recommends libconfig-dev libltdl-dev libreadline8 libncurses6 telnet iproute2 iputils-ping tcpdump && \
    apt-get clean

# Copy over relevant files from build stage, and 'install' them
COPY --from=build /build/artifact.tar /build/
RUN tar -xvf /build/artifact.tar -C / && \
    rm -rf /build 

CMD ["bgpd", "-f", "/etc/quagga.conf"]
