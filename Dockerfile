
# bump: svtav1 /SVTAV1_VERSION=([\d.]+)/ https://gitlab.com/AOMediaCodec/SVT-AV1.git|*
# bump: svtav1 after ./hashupdate Dockerfile SVTAV1 $LATEST
# bump: svtav1 link "Release notes" https://gitlab.com/AOMediaCodec/SVT-AV1/-/releases/v$LATEST
ARG SVTAV1_VERSION=1.2.1
ARG SVTAV1_URL="https://gitlab.com/AOMediaCodec/SVT-AV1/-/archive/v$SVTAV1_VERSION/SVT-AV1-v$SVTAV1_VERSION.tar.bz2"
ARG SVTAV1_SHA256=805827daa8aedec4f1362b959f377075e2a811680bfc76b6f4fbf2ef4e7101d4

# bump: alpine /FROM alpine:([\d.]+)/ docker:alpine|^3
# bump: alpine link "Release notes" https://alpinelinux.org/posts/Alpine-$LATEST-released.html
FROM alpine:3.16.2 AS base

FROM base AS download
ARG SVTAV1_URL
ARG SVTAV1_SHA256
ARG WGET_OPTS="--retry-on-host-error --retry-on-http-error=429,500,502,503 -nv"
WORKDIR /tmp
RUN \
  apk add --no-cache --virtual download \
    coreutils wget tar && \
  wget $WGET_OPTS -O svtav1.tar.bz2 "$SVTAV1_URL" && \
  echo "$SVTAV1_SHA256  svtav1.tar.bz2" | sha256sum --status -c - && \
  mkdir svtav1 && \
  tar xf svtav1.tar.bz2 -C svtav1 --strip-components=1 && \
  rm svtav1.tar.bz2 && \
  apk del download

FROM base AS build 
COPY --from=download /tmp/svtav1/ /tmp/svtav1/
WORKDIR /tmp/svtav1/Build
RUN \
  apk add --no-cache --virtual build \
    build-base cmake nasm && \
  cmake \
    -G"Unix Makefiles" \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    .. && \
  make -j$(nproc) install && \
  apk del build

FROM scratch
ARG SVTAV1_VERSION
COPY --from=build /usr/local/lib/pkgconfig/SvtAv1*.pc /usr/local/lib/pkgconfig/
COPY --from=build /usr/local/lib/libSvtAv1*.a /usr/local/lib/
COPY --from=build /usr/local/include/svt-av1/ /usr/local/include/svt-av1/
