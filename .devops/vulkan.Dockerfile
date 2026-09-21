ARG UBUNTU_VERSION=26.04@sha256:da6fc2be547864451aa253836dd926da33623312df4a9a243e35dc877c378a78
ARG BUILD_DATE=N/A
ARG APP_VERSION=N/A
ARG APP_REVISION=N/A

ARG NODE_VERSION=24-bookworm-slim@sha256:0e0ff40c39bc087845bfb27465a0df4ea419520094bc35842ff83dd8cbe6f9b6

FROM docker.io/node:$NODE_VERSION AS web

ARG APP_VERSION

WORKDIR /app/tools/ui

COPY tools/ui/package.json tools/ui/package-lock.json ./
RUN npm ci

COPY tools/ui/ ./
RUN LLAMA_BUILD_NUMBER="$APP_VERSION" npm run build
RUN mkdir /licenses && find node_modules -type f \( -iname '*license*' -o -iname '*notice*' -o -iname '*copying*' \) -exec cp --parents '{}' /licenses/ \;

FROM docker.io/ubuntu:$UBUNTU_VERSION AS build

# Install build tools
RUN apt update && apt install -y git build-essential cmake wget xz-utils

# Install SSL and Vulkan SDK dependencies
RUN apt install -y libssl-dev curl \
    libxcb-xinput0 libxcb-xinerama0 libxcb-cursor-dev libvulkan-dev glslc spirv-headers

# Build it
WORKDIR /app

COPY . .

COPY --from=web /app/tools/ui/dist tools/ui/dist

ARG APP_REVISION
ARG BUILD_JOBS=2
RUN cmake -B build -DCMAKE_BUILD_TYPE=Release -DLLAMA_BUILD_COMMIT="$APP_REVISION" -DGGML_NATIVE=OFF -DGGML_VULKAN=ON -DLLAMA_BUILD_TESTS=OFF -DGGML_BACKEND_DL=ON -DGGML_CPU_ALL_VARIANTS=ON && \
    cmake --build build --config Release -j"$BUILD_JOBS"

RUN mkdir -p /app/lib && \
    find build -name "*.so*" -exec cp -P {} /app/lib \;

RUN mkdir -p /app/full \
    && cp build/bin/* /app/full \
    && cp *.py /app/full \
    && cp -r conversion /app/full \
    && cp -r gguf-py /app/full \
    && cp -r requirements /app/full \
    && cp requirements.txt /app/full \
    && cp .devops/tools.sh /app/full/tools.sh

RUN mkdir -p /app/build-info /app/licenses && \
    c++ --version > /app/build-info/compiler.txt && \
    dpkg-query -W > /app/build-info/build-packages.tsv && \
    cp LICENSE AUTHORS /app/licenses/ && \
    find vendor -type f \( -iname '*license*' -o -iname '*notice*' -o -iname '*copying*' \) -exec cp --parents '{}' /app/licenses/ \;

## Base image
FROM docker.io/ubuntu:$UBUNTU_VERSION AS base

ARG BUILD_DATE=N/A
ARG APP_VERSION=N/A
ARG APP_REVISION=N/A
ARG IMAGE_URL=https://github.com/ggml-org/llama.cpp
ARG IMAGE_SOURCE=https://github.com/ggml-org/llama.cpp
LABEL org.opencontainers.image.created=$BUILD_DATE \
      org.opencontainers.image.version=$APP_VERSION \
      org.opencontainers.image.revision=$APP_REVISION \
      org.opencontainers.image.title="llama.cpp" \
      org.opencontainers.image.description="LLM inference in C/C++" \
      org.opencontainers.image.url=$IMAGE_URL \
      org.opencontainers.image.source=$IMAGE_SOURCE

RUN apt-get update \
    && apt-get install -y libgomp1 curl ffmpeg libvulkan1 mesa-vulkan-drivers \
    libglvnd0 libgl1 libglx0 libegl1 libgles2 \
    && apt autoremove -y \
    && apt clean -y \
    && rm -rf /tmp/* /var/tmp/* \
    && find /var/cache/apt/archives /var/lib/apt/lists -not -name lock -type f -delete \
    && find /var/cache -type f -delete

COPY --from=build /app/lib/ /app
COPY --from=build /app/build-info/ /usr/share/strix/
COPY --from=build /app/licenses/ /usr/share/licenses/strix/
COPY --from=web /licenses/ /usr/share/licenses/strix-ui/
COPY tools/ui/package-lock.json /usr/share/strix/package-lock.json
RUN dpkg-query -W > /usr/share/strix/runtime-packages.tsv

### Full
FROM base AS full

COPY --from=build /app/full /app

WORKDIR /app

ENV PATH="/root/.venv/bin:/root/.local/bin:${PATH}"

# Flag for compatibility with pip
ARG UV_INDEX_STRATEGY="unsafe-best-match"
RUN apt-get update \
    && apt-get install -y \
    build-essential \
    curl \
    git \
    ca-certificates \
    && curl -LsSf https://astral.sh/uv/install.sh | sh \
    && uv python install 3.13 \
    && uv venv --python 3.13 /root/.venv \
    && uv pip install --python /root/.venv/bin/python -r requirements.txt \
    && apt autoremove -y \
    && apt clean -y \
    && rm -rf /tmp/* /var/tmp/* \
    && find /var/cache/apt/archives /var/lib/apt/lists -not -name lock -type f -delete \
    && find /var/cache -type f -delete

ENTRYPOINT ["/app/tools.sh"]

### Light, CLI only
FROM base AS light

COPY --from=build /app/full/llama /app/full/llama-cli /app/full/llama-completion /app

WORKDIR /app

ENTRYPOINT [ "/app/llama-cli" ]

### Server, Server only
FROM base AS server

ENV LLAMA_ARG_HOST=0.0.0.0

COPY --from=build /app/full/llama /app/full/llama-server /app

WORKDIR /app

HEALTHCHECK CMD [ "curl", "-f", "http://localhost:8080/health" ]

ENTRYPOINT [ "/app/llama-server" ]
