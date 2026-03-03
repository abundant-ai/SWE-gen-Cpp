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
    (git fetch --depth 1 origin dab0f95a949099e2615e8ba7ad0606ef84d2061c || git fetch --depth 1 origin "+refs/pull/28217/head:refs/remotes/origin/pr/28217") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Set environment variable for test data path
ENV OPENCV_TEST_DATA_PATH=/app/extra/testdata

# Configure and build OpenCV with CMake
# Build with AddressSanitizer to detect memory errors
# Only build video test to save time
RUN cmake -Bbuild -H. \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_FLAGS="-g -fsanitize=address -fno-omit-frame-pointer" \
    -DCMAKE_C_FLAGS="-g -fsanitize=address -fno-omit-frame-pointer" \
    -DCMAKE_EXE_LINKER_FLAGS="-fsanitize=address" \
    -DCMAKE_MODULE_LINKER_FLAGS="-fsanitize=address" \
    -DCMAKE_SHARED_LINKER_FLAGS="-fsanitize=address" \
    -DBUILD_TESTS=ON \
    -DBUILD_PERF_TESTS=OFF \
    -DBUILD_opencv_video=ON \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_DOCS=OFF \
    -DBUILD_opencv_apps=OFF \
    -G Ninja

# Build only the video test target
RUN cmake --build build --target opencv_test_video -j4

# Reset any build artifacts so bug.patch applies cleanly
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Reconfigure and rebuild after applying bug.patch (C++ is a compiled language)
# Need to reconfigure because bug.patch deletes test files and modifies source
# Keep ASan enabled
RUN cmake -Bbuild -H. \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_FLAGS="-g -fsanitize=address -fno-omit-frame-pointer" \
    -DCMAKE_C_FLAGS="-g -fsanitize=address -fno-omit-frame-pointer" \
    -DCMAKE_EXE_LINKER_FLAGS="-fsanitize=address" \
    -DCMAKE_MODULE_LINKER_FLAGS="-fsanitize=address" \
    -DCMAKE_SHARED_LINKER_FLAGS="-fsanitize=address" \
    -DBUILD_TESTS=ON \
    -DBUILD_PERF_TESTS=OFF \
    -DBUILD_opencv_video=ON \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_DOCS=OFF \
    -DBUILD_opencv_apps=OFF \
    -G Ninja && \
    cmake --build build --target opencv_test_video -j4

RUN rm -rf /app/src/.git

WORKDIR /app/src
