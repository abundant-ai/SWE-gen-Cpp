FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/opencv/opencv.git src && \
    cd src && \
    (git fetch --depth 1 origin bbf39b0964e9246358877b0d72391e9c0b010f0d || git fetch --depth 1 origin "+refs/pull/13880/head:refs/remotes/origin/pr/13880") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
# Delete binary file manually and apply patch with --binary flag
RUN rm -f modules/calib3d/doc/pics/hand-eye_figure.png && \
    patch -p1 --binary --forward --no-backup-if-mismatch < /tmp/bug.patch || \
    (echo "Patch may have partially failed due to binary files, continuing..." && \
     git status && \
     test -f modules/calib3d/src/calibration_handeye.cpp && echo "ERROR: Source file still exists!" && exit 1 || true) && \
    rm /tmp/bug.patch

# Test validation checks source code state without building the full project
# to avoid extremely long build times (OpenCV takes 30+ minutes to compile)

RUN rm -rf /app/src/.git

WORKDIR /app/src
