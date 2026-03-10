FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    cmake \
    libgtest-dev \
    libgmock-dev \
    locales \
    && rm -rf /var/lib/apt/lists/*

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    sed -i '/de_DE.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen

WORKDIR /app

RUN git clone https://github.com/jbeder/yaml-cpp.git src && \
    cd src && \
    (git fetch --depth 1 origin 6cd1e51d1ea07e49da7267bd412af225ff9e60dc || git fetch --depth 1 origin "+refs/pull/906/head:refs/remotes/origin/pr/906") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

RUN mkdir -p build && cd build && \
    cmake .. \
    -DYAML_CPP_BUILD_TESTS=ON \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_CXX_FLAGS="-Wno-error=maybe-uninitialized" && \
    make -j2

RUN git reset --hard

COPY bug.patch /tmp/bug.patch
RUN rm -f src/.emitterstate.h.swp && \
    patch -p1 --force < /tmp/bug.patch && \
    rm /tmp/bug.patch

RUN cd build && make -j2

RUN rm -rf /app/src/.git

WORKDIR /app/src
