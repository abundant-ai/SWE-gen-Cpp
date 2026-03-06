FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install .NET SDK 6.0 dependencies and runtime
RUN apt-get update && apt-get install -y \
    wget \
    libicu74 \
    && rm -rf /var/lib/apt/lists/*

# Install .NET SDK 6.0
RUN wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh \
    && chmod +x dotnet-install.sh \
    && ./dotnet-install.sh --channel 6.0 --install-dir /usr/share/dotnet \
    && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet \
    && rm dotnet-install.sh

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/protocolbuffers/protobuf.git src && \
    cd src && \
    (git fetch --depth 1 origin c3ddacbd2e67af0f7bbd463ebbe3db814bd5291b || git fetch --depth 1 origin "+refs/pull/23837/head:refs/remotes/origin/pr/23837") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Set environment variables for .NET
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
ENV DOTNET_SKIP_FIRST_TIME_EXPERIENCE=true
ENV CI=true

# Restore and build C# solution
RUN cd csharp && \
    dotnet restore src/Google.Protobuf.sln && \
    dotnet build -c Release src/Google.Protobuf.sln

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Rebuild after applying bug.patch
RUN cd csharp && \
    dotnet build -c Release src/Google.Protobuf.sln

RUN rm -rf /app/src/.git

WORKDIR /app/src
