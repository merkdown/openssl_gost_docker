FROM ubuntu:22.04

SHELL ["/bin/bash", "-c"]
ARG DEBIAN_FRONTEND=noninteractive

ENV TZ=Europe/Moscow
ENV OPENSSL_ENGINES_DIR=/usr/local/ssl/lib64/engines-3
ENV OPENSSL_DIR=/usr/local/ssl
ENV CURL_DIR=/usr/local/curl
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:/usr/local/ssl/bin:/usr/local/curl/bin"

RUN apt update && apt upgrade -y && apt install vim tzdata git make cmake libz-dev libssl-dev pkg-config wget libpsl-dev -y

WORKDIR /opt/openssl
RUN git clone --branch openssl-3.3.2 https://github.com/openssl/openssl.git .
RUN git submodule update --init --recursive
RUN ./config --prefix=$OPENSSL_DIR --openssldir=$OPENSSL_DIR shared zlib
RUN make -j 12 && make -j 12 install
RUN echo "/usr/local/ssl/lib64" > /etc/ld.so.conf.d/openssl-3.3.2.conf && ldconfig -v
RUN mv /usr/bin/c_rehash /opt/c_rehash.bak && mv /usr/bin/openssl /opt/openssl.bak

WORKDIR /opt/openssl/gost-engine
RUN cmake -DOPENSSL_ROOT_DIR=$OPENSSL_DIR -DOPENSSL_ENGINES_DIR=$OPENSSL_ENGINES_DIR .
RUN cmake --build . --target install --config Release

WORKDIR /usr/local/ssl
COPY ./openssl_copy_gost.cnf openssl.cnf

WORKDIR /opt/
RUN wget --no-check-certificate https://curl.se/download/curl-8.10.1.tar.gz 
RUN tar -xf curl-8.10.1.tar.gz -C . && mv curl-8.10.1 curl
RUN rm -rf *.tar.gz

WORKDIR /opt/curl
RUN ./configure --prefix=$CURL_DIR --with-openssl=$OPENSSL_DIR 
RUN make -j 12 && make -j 12 install

WORKDIR /labs
ARG UNAME=student
ARG UID=1000
ARG GID=1000
RUN groupadd -g $GID -o $UNAME
RUN useradd -m -u $UID -g $GID -o -s /bin/bash $UNAME
RUN chown -R $USERNAME:$USERNAME /labs
USER $UNAME

