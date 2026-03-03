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
    (git fetch --depth 1 origin ca73ab4e3191e8827cdec562990be4c1028475a0 || git fetch --depth 1 origin "+refs/pull/28575/head:refs/remotes/origin/pr/28575") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Download opencv_extra repository for test data
WORKDIR /app
RUN git clone --depth 1 https://github.com/opencv/opencv_extra.git extra

WORKDIR /app/src

# Set environment variable for test data path
ENV OPENCV_TEST_DATA_PATH=/app/extra/testdata

# Configure and build OpenCV with CMake
# We need to enable the DNN module and build tests
RUN cmake -Bbuild -H. \
    -DCMAKE_BUILD_TYPE=Debug \
    -DBUILD_TESTS=ON \
    -DBUILD_PERF_TESTS=OFF \
    -DBUILD_opencv_dnn=ON \
    -DWITH_PROTOBUF=ON \
    -DBUILD_PROTOBUF=ON \
    -DOPENCV_DNN_OPENCL=OFF \
    -G Ninja

# Build OpenCV
RUN cmake --build build

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Rebuild after applying bug.patch (C++ is a compiled language)
RUN cmake --build build

RUN rm -rf /app/src/.git

WORKDIR /app/src
