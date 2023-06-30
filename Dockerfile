FROM ubuntu AS builder

WORKDIR /

RUN apt-get update && \
    apt-get install -y git && \
    git clone https://github.com/emercoin/emercoin.git && \
    cd /emercoin/ && \
    git checkout tags/v0.7.12emc

RUN apt-get install -y libssl-dev

RUN apt-get install -y libboost-all-dev

RUN apt-get install -y libdb5.3++-dev

RUN apt-get install -y pkg-config

RUN apt-get install -y build-essential

RUN apt-get install -y libtool

RUN apt-get install -y autoconf

RUN apt-get install -y bzip2

RUN apt-get install -y libzmq3-dev

WORKDIR /emercoin

RUN ./autogen.sh && \
    ./configure --disable-dependency-tracking \
                --disable-tests --disable-util-tx \
                --disable-gui-tests --enable-bip70 \
                --disable-hardening \
                --disable-debug \
                --with-incompatible-bdb \
                --enable-static \
                --disable-shared && \
    make -j 4 && \ 
    make install


FROM gruebel/upx as upx

COPY --from=builder /emercoin/src/emercoind /emercoind.fat

RUN	upx --best --lzma -o /emercoind /emercoind.fat



FROM ubuntu

WORKDIR /emc

COPY --from=upx /emercoind .

COPY --from=builder /emercoin/src/emercoin-cli .

COPY ./emercoin.conf .

WORKDIR /lib/x86_64-linux-gnu

COPY --from=builder /lib/x86_64-linux-gnu/libboost_filesystem.so.1.74.0 .

RUN ln -s ./libboost_filesystem.so.1.74.0 ./libboost_filesystem.so

COPY --from=builder /lib/x86_64-linux-gnu/libboost_program_options.so.1.74.0 .

RUN ln -s ./libboost_program_options.so.1.74.0 ./libboost_program_options.so

COPY --from=builder /lib/x86_64-linux-gnu/libboost_thread.so.1.74.0 .

COPY --from=builder /lib/x86_64-linux-gnu/libboost_chrono.so.1.74.0 .

COPY --from=builder /lib/x86_64-linux-gnu/libdb_cxx-5.3.so .

COPY --from=builder /lib/x86_64-linux-gnu/libzmq.so.5.2.4 .

RUN ln -s ./libzmq.so.5.2.4 ./libzmq.so.5

COPY --from=builder /lib/x86_64-linux-gnu/libevent_core-2.1.so.7.0.1 .

RUN ln -s ./libevent_core-2.1.so.7.0.1 ./libevent_core-2.1.so.7

COPY --from=builder /lib/x86_64-linux-gnu/libbsd.so.0.11.5 .

RUN ln -s ./libbsd.so.0.11.5 ./libbsd.so.0

COPY --from=builder /lib/x86_64-linux-gnu/libsodium.so.23.3.0 .

RUN ln -s ./libsodium.so.23.3.0 ./libsodium.so.23

COPY --from=builder /lib/x86_64-linux-gnu/libpgm-5.3.so.0.0.128 .

RUN ln -s ./libpgm-5.3.so.0.0.128 ./libpgm-5.3.so.0

COPY --from=builder /lib/x86_64-linux-gnu/libnorm.so.1 .

RUN ln -s ./libnorm.so.1 ./libnorm.so

COPY --from=builder /lib/x86_64-linux-gnu/libmd.so.0.0.5 .

RUN ln -s ./libmd.so.0.0.5 ./libmd.so.0

WORKDIR /usr/lib/x86_64-linux-gnu

COPY --from=builder /usr/lib/x86_64-linux-gnu/libevent_pthreads-2.1.so.7.0.1 .

RUN ln -s ./libevent_pthreads-2.1.so.7.0.1 ./libevent_pthreads-2.1.so.7

COPY --from=builder /usr/lib/x86_64-linux-gnu/libevent-2.1.so.7.0.1 .
 
RUN ln -s ./libevent-2.1.so.7.0.1 ./libevent-2.1.so.7

WORKDIR /emc

EXPOSE 5353/udp

EXPOSE 6661/tcp

EXPOSE 6662/tcp

ENV PATH="/emc:$PATH"

ENTRYPOINT ["/emc/emercoind"]

CMD ["-datadir=/emc", "-conf=/emc/emercoin.conf", "-printtoconsole"]


