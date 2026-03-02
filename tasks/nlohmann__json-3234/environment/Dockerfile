FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install CMake, compilers, and NVIDIA CUDA toolkit for CUDA test
# Using gcc-10 for better compatibility with CUDA 11.5
RUN apt-get update && apt-get install -y \
    cmake \
    ninja-build \
    software-properties-common \
    gcc-10 \
    g++-10 \
    wget \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-10 100 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-10 100 \
    && update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++-10 100 \
    && rm -rf /var/lib/apt/lists/*

# Install NVIDIA CUDA toolkit (needed for nvcc to compile .cu files)
# Using CUDA 11.5 from nvidia repos - this version exhibits the compilation bug fixed in PR #3234
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-keyring_1.0-1_all.deb \
    && dpkg -i cuda-keyring_1.0-1_all.deb \
    && apt-get update \
    && apt-get install -y cuda-nvcc-11-5 cuda-cudart-dev-11-5 \
    && rm -rf /var/lib/apt/lists/* cuda-keyring_1.0-1_all.deb

ENV PATH="/usr/local/cuda-11.5/bin:${PATH}"
ENV LD_LIBRARY_PATH="/usr/local/cuda-11.5/lib64:${LD_LIBRARY_PATH}"

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/nlohmann/json.git src && \
    cd src && \
    (git fetch --depth 1 origin 1ee61bf371bb743029a61f937c9e157c5831004c || git fetch --depth 1 origin "+refs/pull/3234/head:refs/remotes/origin/pr/3234") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Reset tracked files so bug.patch applies cleanly
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

RUN rm -rf /app/src/.git

WORKDIR /app/src
