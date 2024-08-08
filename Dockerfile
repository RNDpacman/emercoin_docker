FROM ubuntu AS builder

ARG EMC_VER=v0.8.5emc

WORKDIR /

RUN apt-get update && apt-get install -y \
            git \
            libssl-dev \
            libboost-all-dev \
            libdb5.3++-dev \
            pkg-config \
            build-essential \
            libtool \
            autoconf \
            bzip2 \
            upx \
            binutils \
            libzmq3-dev \
            pip \
            patchelf \
            python3-venv
            

RUN git clone https://github.com/emercoin/emercoin.git && \
    cd /emercoin/ && \
    git checkout $EMC_VER

WORKDIR /emercoin

RUN ./autogen.sh && \
    ./configure --disable-dependency-tracking \
                --disable-tests --disable-util-tx \
                --disable-gui-tests --enable-bip70 \
                --disable-hardening \
                --disable-debug \
                --with-incompatible-bdb \
                --enable-static \
                --disable-shared

RUN make -j 4 && make install

RUN strip /emercoin/src/emercoind && strip /emercoin/src/emercoin-cli && \
	python3 -m venv staticx && \
	bash -c "source ./staticx/bin/activate && \
	pip install staticx setuptools && \
	staticx --strip /emercoin/src/emercoind /emercoin/src/emercoind_static && \
	staticx --strip /emercoin/src/emercoin-cli /emercoin/src/emercoin-cli_static && \
	deactivate"
	
	

WORKDIR /emercoin/src

RUN bash -c 'if [ ! "$HOSTTYPE" = "s390x" ]; \
             then upx --best --lzma ./emercoind && \
	              upx --best --lzma ./emercoin-cli; fi'

FROM ubuntu

ARG ARCH=x86_64

ARG EMC_VER=v0.8.5emc

LABEL author="wg00" maintainer="info@wg0.xyz"

LABEL org.opencontainers.image.source="https://github.com/RNDpacman/emercoin_docker"

LABEL name="Emercoin "$EMC_VER

WORKDIR /emc

COPY --from=builder /emercoin/src/emercoind_static ./emercoind

COPY --from=builder /emercoin/src/emercoin-cli_static ./emercoin-cli

COPY ./emercoin.conf .

WORKDIR /emc

EXPOSE 5335/udp

EXPOSE 6661/tcp

EXPOSE 6662/tcp

ENV PATH="/emc:$PATH"

ENTRYPOINT ["/emc/emercoind"]

CMD ["-datadir=/emc", "-conf=/emc/emercoin.conf", "-printtoconsole"]


