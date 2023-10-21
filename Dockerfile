FROM ubuntu AS builder

ARG EMC_VER=v0.8.3emc

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
            libzmq3-dev

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

RUN strip /emercoin/src/emercoind && strip /emercoin/src/emercoin-cli

WORKDIR /emercoin/src

RUN bash -c 'if [ ! "$HOSTTYPE" = "s390x" ]; \
             then upx --best --lzma ./emercoind && \
	              upx --best --lzma ./emercoin-cli; fi'


FROM ubuntu

ARG ARCH=x86_64

ARG EMC_VER=v0.7.12emc

#ENV ARCH=$ARCH

LABEL author="wg00" maintainer="wg0@riseup.net"

LABEL org.opencontainers.image.source="https://github.com/RNDpacman/emercoin_docker"

LABEL name="Emercoin "$EMC_VER

WORKDIR /emc

COPY --from=builder /emercoin/src/emercoind ./emercoind

COPY --from=builder /emercoin/src/emercoin-cli ./emercoin-cli

COPY ./emercoin.conf .

WORKDIR /lib/$ARCH-linux-gnu

COPY --from=builder /lib/$ARCH-linux-gnu/libboost_filesystem.so.1.74.0 \
                    /lib/$ARCH-linux-gnu/libmd.so.0.0.5 \
                    /lib/$ARCH-linux-gnu/libnorm.so.1 \
                    /lib/$ARCH-linux-gnu/libpgm-5.3.so.0.0.128 \
                    /lib/$ARCH-linux-gnu/libsodium.so.23.3.0 \
                    /lib/$ARCH-linux-gnu/libbsd.so.0.11.5 \
                    /lib/$ARCH-linux-gnu/libzmq.so.5.2.4 \
                    /lib/$ARCH-linux-gnu/libevent_core-2.1.so.7.0.1 \
                    /lib/$ARCH-linux-gnu/libdb_cxx-5.3.so \
                    /lib/$ARCH-linux-gnu/libboost_chrono.so.1.74.0 \
                    /lib/$ARCH-linux-gnu/libboost_thread.so.1.74.0 \
                    /lib/$ARCH-linux-gnu/libboost_program_options.so.1.74.0 ./

RUN ln -s ./libboost_filesystem.so.1.74.0 ./libboost_filesystem.so && \
    ln -s ./libboost_program_options.so.1.74.0 ./libboost_program_options.so && \
    ln -s ./libzmq.so.5.2.4 ./libzmq.so.5 && \
    ln -s ./libevent_core-2.1.so.7.0.1 ./libevent_core-2.1.so.7 && \
    ln -s ./libbsd.so.0.11.5 ./libbsd.so.0 && \
    ln -s ./libsodium.so.23.3.0 ./libsodium.so.23 && \
    ln -s ./libpgm-5.3.so.0.0.128 ./libpgm-5.3.so.0 && \
    ln -s ./libnorm.so.1 ./libnorm.so && \
    ln -s ./libmd.so.0.0.5 ./libmd.so.0

WORKDIR /usr/lib/$ARCH-linux-gnu

COPY --from=builder /usr/lib/$ARCH-linux-gnu/libevent-2.1.so.7.0.1 \
                    /usr/lib/$ARCH-linux-gnu/libevent_pthreads-2.1.so.7.0.1 .

RUN ln -s ./libevent_pthreads-2.1.so.7.0.1 ./libevent_pthreads-2.1.so.7 && \
    ln -s ./libevent-2.1.so.7.0.1 ./libevent-2.1.so.7

WORKDIR /emc

EXPOSE 5335/udp

EXPOSE 6661/tcp

EXPOSE 6662/tcp

ENV PATH="/emc:$PATH"

ENTRYPOINT ["/emc/emercoind"]

CMD ["-datadir=/emc", "-conf=/emc/emercoin.conf", "-printtoconsole"]


