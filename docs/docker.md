# Docker

## This fork's Vulkan image

A sync or push to `master` starts only [Publish Vulkan image](../.github/workflows/docker.yml). It builds one Linux amd64 Vulkan `server` image, matching the home lab's backend and architecture. The inherited CANN workflow has no active jobs and is stored as `build-cann.yml.disabled` to avoid GitHub validation failures. Other inherited workflows have no push triggers; their manual, pull-request, reusable, and scheduled triggers remain as configured. A single sync builds the pushed branch tip, not each imported commit.

New runs cancel older pending or running image workflows on the same ref using [GitHub Actions concurrency](https://docs.github.com/en/actions/concepts/workflows-and-actions/concurrency). The build and publication steps also check the current `master` SHA and reject obsolete revisions, including reruns of old commits. Cancellation can leave partial artifacts; already published immutable images remain available. Manual publication is limited to current `master`; pull requests build and scan without publishing.

When resolving an upstream sync, preserve this trigger policy and check newly added workflows for push triggers. Syncing with a discard/reset operation can erase fork-specific CI changes. Publishing an image does not update the home-lab deployment: adopt the tested image reference and digest separately through GitOps.

This fork publishes `ghcr.io/vitorcaleffi/strix-llama-cpp` from the existing `.devops/vulkan.Dockerfile`, `server` target, for Linux amd64. The UI, Mesa RADV, curl and shared libraries are included. CPU native tuning is disabled and CMake uses Release mode. Base images are pinned by digest; compiler and installed package versions are recorded under `/usr/share/strix`. OS packages resolve at build time, so each build has a unique tag and deployment must include its digest.

The `Publish Vulkan image` workflow builds and tests on GitHub-hosted runners. Pull requests build without publishing. Pushes to `master` and manual runs on `master` publish only after executable/library/backend checks and a fixable-critical vulnerability gate. Publication runs in a separate job with `packages: write`; build jobs receive no registry credentials. The context is a Git archive, with no `.git`, checkout credentials or private homelab files. There are no scheduled rebuilds, upstream-style release tags or `latest` tags.

After first publication, make the package public in [package settings](https://github.com/users/VitorCaleffi/packages/container/strix-llama-cpp/settings). If GitHub Actions are disabled for this new fork, enable them in its Actions tab first. The workflow's `image-reference` artifact contains `ghcr.io/vitorcaleffi/strix-llama-cpp:vulkan-<commit>-<run>-<attempt>@sha256:<digest>`. The final step tests an anonymous pull; if it fails because visibility was private, make the package public and verify the artifact reference with `DOCKER_CONFIG` set to a new empty directory before deploying. A new workflow attempt gets a new tag.

Keep every deployed digest and rollback digest. Update source with explicit Git changes, build, then promote the chosen digest in the deployment repository. The existing `full` target includes benchmark tools and is separate from the published `server` image. CI does not validate GPU inference, model correctness or performance on Strix Halo hardware.

## Prerequisites
* Docker must be installed and running on your system.
* Create a folder to store big models & intermediate files (ex. /llama/models)

## Images
We have three Docker images available for this project:

1. `ghcr.io/ggml-org/llama.cpp:full`: This image includes both the `llama-cli` and `llama-completion` executables and the tools to convert LLaMA models into ggml and convert into 4-bit quantization. (platforms: `linux/amd64`, `linux/arm64`, `linux/s390x`)
2. `ghcr.io/ggml-org/llama.cpp:light`: This image only includes the `llama-cli` and `llama-completion` executables. (platforms: `linux/amd64`, `linux/arm64`, `linux/s390x`)
3. `ghcr.io/ggml-org/llama.cpp:server`: This image only includes the `llama-server` executable. (platforms: `linux/amd64`, `linux/arm64`, `linux/s390x`)

Additionally, there the following images, similar to the above:

- `ghcr.io/ggml-org/llama.cpp:full-cuda`: Same as `full` but compiled with CUDA 12 support. (platforms: `linux/amd64`, `linux/arm64`)
- `ghcr.io/ggml-org/llama.cpp:full-cuda13`: Same as `full` but compiled with CUDA 13 support. (platforms: `linux/amd64`, `linux/arm64`)
- `ghcr.io/ggml-org/llama.cpp:light-cuda`: Same as `light` but compiled with CUDA 12 support. (platforms: `linux/amd64`, `linux/arm64`)
- `ghcr.io/ggml-org/llama.cpp:light-cuda13`: Same as `light` but compiled with CUDA 13 support. (platforms: `linux/amd64`, `linux/arm64`)
- `ghcr.io/ggml-org/llama.cpp:server-cuda`: Same as `server` but compiled with CUDA 12 support. (platforms: `linux/amd64`, `linux/arm64`)
- `ghcr.io/ggml-org/llama.cpp:server-cuda13`: Same as `server` but compiled with CUDA 13 support. (platforms: `linux/amd64`, `linux/arm64`)
- `ghcr.io/ggml-org/llama.cpp:full-rocm`: Same as `full` but compiled with ROCm support. (platforms: `linux/amd64`)
- `ghcr.io/ggml-org/llama.cpp:light-rocm`: Same as `light` but compiled with ROCm support. (platforms: `linux/amd64`)
- `ghcr.io/ggml-org/llama.cpp:server-rocm`: Same as `server` but compiled with ROCm support. (platforms: `linux/amd64`)
- `ghcr.io/ggml-org/llama.cpp:full-musa`: Same as `full` but compiled with MUSA support. (platforms: `linux/amd64`)
- `ghcr.io/ggml-org/llama.cpp:light-musa`: Same as `light` but compiled with MUSA support. (platforms: `linux/amd64`)
- `ghcr.io/ggml-org/llama.cpp:server-musa`: Same as `server` but compiled with MUSA support. (platforms: `linux/amd64`)
- `ghcr.io/ggml-org/llama.cpp:full-intel`: Same as `full` but compiled with SYCL support. (platforms: `linux/amd64`)
- `ghcr.io/ggml-org/llama.cpp:light-intel`: Same as `light` but compiled with SYCL support. (platforms: `linux/amd64`)
- `ghcr.io/ggml-org/llama.cpp:server-intel`: Same as `server` but compiled with SYCL support. (platforms: `linux/amd64`)
- `ghcr.io/ggml-org/llama.cpp:full-vulkan`: Same as `full` but compiled with Vulkan support. (platforms: `linux/amd64`, `linux/arm64`)
- `ghcr.io/ggml-org/llama.cpp:light-vulkan`: Same as `light` but compiled with Vulkan support. (platforms: `linux/amd64`, `linux/arm64`)
- `ghcr.io/ggml-org/llama.cpp:server-vulkan`: Same as `server` but compiled with Vulkan support. (platforms: `linux/amd64`, `linux/arm64`)
- `ghcr.io/ggml-org/llama.cpp:full-openvino`: Same as `full` but compiled with OpenVino support. (platforms: `linux/amd64`)
- `ghcr.io/ggml-org/llama.cpp:light-openvino`: Same as `light` but compiled with OpenVino support. (platforms: `linux/amd64`)
- `ghcr.io/ggml-org/llama.cpp:server-openvino`: Same as `server` but compiled with OpenVino support. (platforms: `linux/amd64`)
- `ghcr.io/ggml-org/llama.cpp:full-s390x`: Identical to `full`, an alias for the `s390x` platform. (platforms: `linux/s390x`)
- `ghcr.io/ggml-org/llama.cpp:light-s390x`: Identical to `light`, an alias for the `s390x` platform. (platforms: `linux/s390x`)
- `ghcr.io/ggml-org/llama.cpp:server-s390x`: Identical to `server`, an alias for the `s390x` platform. (platforms: `linux/s390x`)

The GPU enabled images are not currently tested by CI beyond being built. They are not built with any variation from the ones in the Dockerfiles defined in [.devops/](../.devops/) and the GitHub Action defined in [.github/workflows/docker.yml](../.github/workflows/docker.yml). If you need different settings (for example, a different CUDA, ROCm or MUSA library, you'll need to build the images locally for now).

## Usage

The easiest way to download the models, convert them to ggml and optimize them is with the --all-in-one command which includes the full docker image.

Replace `/path/to/models` below with the actual path where you downloaded the models.

```bash
docker run -v /path/to/models:/models ghcr.io/ggml-org/llama.cpp:full --all-in-one "/models/" 7B
```

On completion, you are ready to play!

```bash
docker run -v /path/to/models:/models ghcr.io/ggml-org/llama.cpp:full --run -m /models/7B/ggml-model-q4_0.gguf
docker run -v /path/to/models:/models ghcr.io/ggml-org/llama.cpp:full --run-legacy -m /models/32B/ggml-model-q8_0.gguf -no-cnv -p "Building a mobile app can be done in 15 steps:" -n 512
```

or with a light image:

```bash
docker run -v /path/to/models:/models --entrypoint /app/llama-cli ghcr.io/ggml-org/llama.cpp:light -m /models/7B/ggml-model-q4_0.gguf
docker run -v /path/to/models:/models --entrypoint /app/llama-completion ghcr.io/ggml-org/llama.cpp:light -m /models/32B/ggml-model-q8_0.gguf -no-cnv -p "Building a mobile app can be done in 15 steps:" -n 512
```

or with a server image:

```bash
docker run -v /path/to/models:/models -p 8080:8080 ghcr.io/ggml-org/llama.cpp:server -m /models/7B/ggml-model-q4_0.gguf --port 8080 --host 0.0.0.0 -n 512
```

In the above examples, `--entrypoint /app/llama-cli` is specified for clarity, but you can safely omit it since it's the default entrypoint in the container.

## Docker With CUDA

Assuming one has the [nvidia-container-toolkit](https://github.com/NVIDIA/nvidia-container-toolkit) properly installed on Linux, or is using a GPU enabled cloud, `cuBLAS` should be accessible inside the container.

## Building Docker locally

```bash
docker build -t local/llama.cpp:full-cuda --target full -f .devops/cuda.Dockerfile .
docker build -t local/llama.cpp:light-cuda --target light -f .devops/cuda.Dockerfile .
docker build -t local/llama.cpp:server-cuda --target server -f .devops/cuda.Dockerfile .
```

You may want to pass in some different `ARGS`, depending on the CUDA environment supported by your container host, as well as the GPU architecture.

The defaults are:

- `CUDA_VERSION` set to `12.8.1`
- `CUDA_DOCKER_ARCH` set to the cmake build default, which includes all the supported architectures

The resulting images, are essentially the same as the non-CUDA images:

1. `local/llama.cpp:full-cuda`: This image includes both the `llama-cli` and `llama-completion` executables and the tools to convert LLaMA models into ggml and convert into 4-bit quantization.
2. `local/llama.cpp:light-cuda`: This image only includes the `llama-cli` and `llama-completion` executables.
3. `local/llama.cpp:server-cuda`: This image only includes the `llama-server` executable.

## Usage

After building locally, Usage is similar to the non-CUDA examples, but you'll need to add the `--gpus` flag. You will also want to use the `--n-gpu-layers` flag.

```bash
docker run --gpus all -v /path/to/models:/models local/llama.cpp:full-cuda --run -m /models/7B/ggml-model-q4_0.gguf -p "Building a website can be done in 10 simple steps:" -n 512 --n-gpu-layers 1
docker run --gpus all -v /path/to/models:/models local/llama.cpp:light-cuda -m /models/7B/ggml-model-q4_0.gguf -p "Building a website can be done in 10 simple steps:" -n 512 --n-gpu-layers 1
docker run --gpus all -v /path/to/models:/models local/llama.cpp:server-cuda -m /models/7B/ggml-model-q4_0.gguf --port 8080 --host 0.0.0.0 -n 512 --n-gpu-layers 1
```

## Docker With MUSA

Assuming one has the [mt-container-toolkit](https://developer.mthreads.com/musa/native) properly installed on Linux, `muBLAS` should be accessible inside the container.

## Building Docker locally

```bash
docker build -t local/llama.cpp:full-musa --target full -f .devops/musa.Dockerfile .
docker build -t local/llama.cpp:light-musa --target light -f .devops/musa.Dockerfile .
docker build -t local/llama.cpp:server-musa --target server -f .devops/musa.Dockerfile .
```

You may want to pass in some different `ARGS`, depending on the MUSA environment supported by your container host, as well as the GPU architecture.

The defaults are:

- the base image is the MUSA 5.2.0 image from the Moore Threads registry

The resulting images, are essentially the same as the non-MUSA images:

1. `local/llama.cpp:full-musa`: This image includes both the `llama-cli` and `llama-completion` executables and the tools to convert LLaMA models into ggml and convert into 4-bit quantization.
2. `local/llama.cpp:light-musa`: This image only includes the `llama-cli` and `llama-completion` executables.
3. `local/llama.cpp:server-musa`: This image only includes the `llama-server` executable.

## Usage

After building locally, Usage is similar to the non-MUSA examples, but you'll need to set `mthreads` as default Docker runtime. This can be done by executing `(cd /usr/bin/musa && sudo ./docker setup $PWD)` and verifying the changes by executing `docker info | grep mthreads` on the host machine. You will also want to use the `--n-gpu-layers` flag.

```bash
docker run -v /path/to/models:/models local/llama.cpp:full-musa --run -m /models/7B/ggml-model-q4_0.gguf -p "Building a website can be done in 10 simple steps:" -n 512 --n-gpu-layers 1
docker run -v /path/to/models:/models local/llama.cpp:light-musa -m /models/7B/ggml-model-q4_0.gguf -p "Building a website can be done in 10 simple steps:" -n 512 --n-gpu-layers 1
docker run -v /path/to/models:/models local/llama.cpp:server-musa -m /models/7B/ggml-model-q4_0.gguf --port 8080 --host 0.0.0.0 -n 512 --n-gpu-layers 1
```

## Docker With SYCL

## Building Docker locally

```bash
docker build -t local/llama.cpp:full-intel --target full -f .devops/intel.Dockerfile .
docker build -t local/llama.cpp:light-intel --target light -f .devops/intel.Dockerfile .
docker build -t local/llama.cpp:server-intel --target server -f .devops/intel.Dockerfile .
```

You may want to pass in some different `ARGS`, depending on the SYCL environment supported by your container host, as well as the GPU architecture.
Refer to [.devops/intel.Dockerfile](../.devops/intel.Dockerfile) for the available `ARGS` and their defaults.

The resulting images, are essentially the same as the non-SYCL images:

1. `local/llama.cpp:full-intel`: This image includes both the `llama-cli` and `llama-completion` executables and the tools to convert LLaMA models into ggml and convert into 4-bit quantization.
2. `local/llama.cpp:light-intel`: This image only includes the `llama-cli` and `llama-completion` executables.
3. `local/llama.cpp:server-intel`: This image only includes the `llama-server` executable.

## Usage

After building locally, usage is similar to the non-SYCL examples, but you'll need to add the `--device` flag.

```bash
# First, find all the DRI cards
ls -la /dev/dri
# Then, pick the card that you want to use (here for e.g. /dev/dri/card0).
docker run --device /dev/dri/renderD128:/dev/dri/renderD128 --device /dev/dri/card0:/dev/dri/card0 -v /path/to/models:/models local/llama.cpp:full-intel -m /models/7B/ggml-model-q4_0.gguf -p "Building a website can be done in 10 simple steps:" -n 512 --n-gpu-layers 99
docker run --device /dev/dri/renderD128:/dev/dri/renderD128 --device /dev/dri/card0:/dev/dri/card0 -v /path/to/models:/models local/llama.cpp:light-intel -m /models/7B/ggml-model-q4_0.gguf -p "Building a website can be done in 10 simple steps:" -n 512 --n-gpu-layers 99
docker run --device /dev/dri/renderD128:/dev/dri/renderD128 --device /dev/dri/card0:/dev/dri/card0 -v /path/to/models:/models local/llama.cpp:server-intel -m /models/7B/ggml-model-q4_0.gguf --port 8080 --host 0.0.0.0 -n 512 --n-gpu-layers 99
```

*Notes:*
- Docker has been tested successfully on native Linux. WSL support has not been verified yet.
- You may need to install Intel GPU driver on the **host** machine *(Please refer to the [Linux configuration](./backend/SYCL.md#linux) for details)*.
