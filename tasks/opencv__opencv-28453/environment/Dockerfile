FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install C++ build tools, CMake, and Python (needed for some OpenCV scripts)
RUN apt-get update && apt-get install -y \
    cmake \
    ninja-build \
    g++ \
    python3 \
    python3-numpy \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/opencv/opencv.git src && \
    cd src && \
    (git fetch --depth 1 origin 3405c7a1a182ad23a09f59ce19614200e7e8ac35 || git fetch --depth 1 origin "+refs/pull/28453/head:refs/remotes/origin/pr/28453") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

# Download opencv_extra repository for test data
WORKDIR /app
RUN git clone --depth 1 https://github.com/opencv/opencv_extra.git extra

WORKDIR /app/src

# Set environment variable for test data path
ENV OPENCV_TEST_DATA_PATH=/app/extra/testdata

# Configure and build OpenCV with CMake
# Only build dnn test to save time
RUN cmake -Bbuild -H. \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTS=ON \
    -DBUILD_PERF_TESTS=OFF \
    -DBUILD_opencv_dnn=ON \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_DOCS=OFF \
    -DBUILD_opencv_apps=OFF \
    -G Ninja

# Build only the dnn test target with more parallelism
RUN cmake --build build --target opencv_test_dnn -j4

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Reconfigure and rebuild after applying bug.patch (C++ is a compiled language)
# Need to reconfigure because bug.patch may delete/add source files
RUN cmake -Bbuild -H. \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTS=ON \
    -DBUILD_PERF_TESTS=OFF \
    -DBUILD_opencv_dnn=ON \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_DOCS=OFF \
    -DBUILD_opencv_apps=OFF \
    -G Ninja && \
    cmake --build build --target opencv_test_dnn -j4

RUN rm -rf /app/src/.git

WORKDIR /app/src
