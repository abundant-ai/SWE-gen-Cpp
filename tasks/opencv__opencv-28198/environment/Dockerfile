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

# Download opencv_extra repository for test data
RUN git clone --depth 1 https://github.com/opencv/opencv_extra.git extra

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/opencv/opencv.git src && \
    cd src && \
    (git fetch --depth 1 origin 9f1a2d37365b6929b6fef406e9d843e72f9e8616 || git fetch --depth 1 origin "+refs/pull/28198/head:refs/remotes/origin/pr/28198") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Set environment variable for test data path
ENV OPENCV_TEST_DATA_PATH=/app/extra/testdata

# Configure and build OpenCV with CMake
# Only build gapi test to save time
RUN cmake -Bbuild -H. \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTS=ON \
    -DBUILD_PERF_TESTS=OFF \
    -DBUILD_opencv_gapi=ON \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_DOCS=OFF \
    -DBUILD_opencv_apps=OFF \
    -G Ninja

# Build only the gapi test target
RUN cmake --build build --target opencv_test_gapi -j4

# Reset any build artifacts so bug.patch applies cleanly
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Reconfigure and rebuild after applying bug.patch (C++ is a compiled language)
# Need to reconfigure because bug.patch modifies source files
RUN cmake -Bbuild -H. \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTS=ON \
    -DBUILD_PERF_TESTS=OFF \
    -DBUILD_opencv_gapi=ON \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_DOCS=OFF \
    -DBUILD_opencv_apps=OFF \
    -G Ninja && \
    cmake --build build --target opencv_test_gapi -j4

RUN rm -rf /app/src/.git

WORKDIR /app/src
