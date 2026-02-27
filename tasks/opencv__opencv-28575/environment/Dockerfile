FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install C++ build tools and CMake
RUN apt-get update && apt-get install -y \
    cmake \
    ninja-build \
    python3 \
    python3-numpy \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/opencv/opencv.git src && \
    cd src && \
    (git fetch --depth 1 origin ca73ab4e3191e8827cdec562990be4c1028475a0 || git fetch --depth 1 origin "+refs/pull/28575/head:refs/remotes/origin/pr/28575") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

# Clone opencv_extra for test data (matching 5.x branch)
RUN git clone --depth 1 --branch 5.x https://github.com/opencv/opencv_extra.git /app/opencv_extra

WORKDIR /app/src

# Build OpenCV with minimal configuration (DNN module + dependencies for tests)
RUN mkdir -p /app/build && cd /app/build && \
    cmake -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTS=ON \
    -DBUILD_PERF_TESTS=OFF \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_opencv_apps=OFF \
    -DBUILD_DOCS=OFF \
    -DWITH_CUDA=OFF \
    -DWITH_OPENCL=OFF \
    /app/src && \
    ninja opencv_test_dnn

# Reset source files before applying bug.patch
WORKDIR /app/src
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Rebuild after applying bug.patch (required for C++)
RUN cd /app/build && ninja opencv_test_dnn

RUN rm -rf /app/src/.git

WORKDIR /app/src
