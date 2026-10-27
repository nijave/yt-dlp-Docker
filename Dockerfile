# syntax=docker/dockerfile:1

FROM lscr.io/linuxserver/ffmpeg:latest@sha256:6547359fac23a2747e606d380e10267b2923a38f68485d9cacefd039e74d3aa8

# Upstream versions are pinned here and bumped by Renovate
# (customManagers:dockerfileVersions in renovate.json).

# yt-dlp nightly builds are published to PyPI as .devN pre-releases. A
# pre-release pin keeps the image on the nightly channel (YouTube fixes land
# there weeks before a stable release); Renovate follows newer pre-releases
# because the current value is already one.
# renovate: datasource=pypi depName=yt-dlp
ARG YT_DLP_VERSION=2026.10.26

# The PO Token plugin major must match the bgutil-ytdlp-pot-provider server
# (the sidecar in vmubtkube-a yt-dlp.yaml, currently 2.x).
# renovate: datasource=pypi depName=bgutil-ytdlp-pot-provider
ARG BGUTIL_YTDLP_POT_PROVIDER_VERSION=2.0.2

# Deno: JavaScript runtime used by yt-dlp to solve YouTube's sig/nsig challenges.
# Without it, YouTube extraction falls back to deprecated client shortcuts.
# renovate: datasource=github-releases depName=denoland/deno
ARG DENO_VERSION=v2.9.8

WORKDIR /

RUN apt-get update \
  && apt-get install -y --no-install-recommends python3 python3-virtualenv python3-pip python3-setuptools python3-wheel \
  && python3 -m virtualenv venv \
  && venv/bin/python3 -m pip install --no-cache-dir \
    "yt-dlp[default]==${YT_DLP_VERSION}" \
    "bgutil-ytdlp-pot-provider==${BGUTIL_YTDLP_POT_PROVIDER_VERSION}" \
  && apt-get remove --purge -y python3-pip python3-setuptools python3-wheel \
  && apt-get autoremove -y \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
  && apt-get install -y --no-install-recommends unzip \
  && curl -fsSL "https://github.com/denoland/deno/releases/download/${DENO_VERSION}/deno-x86_64-unknown-linux-gnu.zip" -o /tmp/deno.zip \
  && unzip -o /tmp/deno.zip -d /usr/local/bin \
  && chmod +x /usr/local/bin/deno \
  && rm -f /tmp/deno.zip \
  && apt-get remove --purge -y unzip \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

ENV XDG_CACHE_HOME=/tmp
ENV PATH="/venv/bin:$PATH"

RUN mkdir -p /usr/share/yt-dlp
COPY usr/share/yt-dlp/download.py /usr/share/yt-dlp/

# System-wide yt-dlp defaults (rate limiting, SponsorBlock, NFS resilience,
# and the bgutil PO Token provider endpoint). Applied to every job.
COPY etc/yt-dlp.conf /etc/yt-dlp.conf

ENV MEDIA_ROOT=/media
ENV CHECK_FREQUENCY=7200

ENTRYPOINT ["/venv/bin/python3", "/usr/share/yt-dlp/download.py"]
