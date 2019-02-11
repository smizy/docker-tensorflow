FROM smizy/bazel:0.15.0-alpine as bazel

# ----------

FROM smizy/scikit-learn:0.20.2-alpine

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
ARG EXTRA_BAZEL_ARGS

LABEL \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.docker.dockerfile="/Dockerfile" \
    org.label-schema.license="Apache License 2.0" \
    org.label-schema.name="smizy/tensorflow" \
    org.label-schema.url="https://gitlab.com/smizy" \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-type="Git" \
    org.label-schema.version=$VERSION \
    org.label-schema.vcs-url="https://github.com/smizy/docker-tensorflow"

ENV TENSORFLOW_VERSION  $VERSION
ENV EXTRA_BAZEL_ARGS    ${EXTRA_BAZEL_ARGS:-"--local_resources 3072,1.0,1.0"}

ENV JAVA_HOME  /usr/lib/jvm/default-jvm

COPY --from=bazel /usr/local/bin/bazel  /usr/local/bin/

COPY tensorflow.bzl.alpine.patch  /tmp/

RUN set -x \
    && apk update \
    # - tensorFlow build dependencies
    && apk --no-cache add \
        # jemalloc \
        libc6-compat \
        libexecinfo \
        libunwind \
    && apk --no-cache add --virtual .builddeps \
        bash \
        build-base \
        libexecinfo-dev \
        libunwind-dev \
        linux-headers \
        openjdk8 \
        patch \
        perl \
        python3-dev \
        sed \
    && pip3 install wheel \
    && pip3 install keras_applications==1.0.6 --no-deps \
    && pip3 install keras_preprocessing==1.0.5 --no-deps \
    # - source
    && wget -q -O - https://github.com/tensorflow/tensorflow/archive/v${TENSORFLOW_VERSION}.tar.gz \
        | tar -xzf - -C /tmp \
    && cd /tmp/tensorflow-* \
    && echo | \
        CC_OPT_FLAGS=-march=native \
        PYTHON_BIN_PATH=/usr/bin/python \
        TF_NEED_MKL=0 \
        TF_NEED_VERBS=0 \
        TF_NEED_CUDA=0 \
        TF_NEED_GCP=0 \
        TF_NEED_JEMALLOC=0 \
        TF_NEED_HDFS=0 \
        TF_NEED_OPENCL=0 \
        TF_ENABLE_XLA=0 \
        TF_NEED_MPI=0 \
        ./configure \
    # - patch: add -lexecinfo for missing backtrace symbol
    && patch -p1 < /tmp/tensorflow.bzl.alpine.patch \
    && bazel build -c opt ${EXTRA_BAZEL_ARGS} \
        --incompatible_remove_native_http_archive=false \
        //tensorflow/tools/pip_package:build_pip_package \
    && bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg \
    ## tensorflow install dependencies
    && apk --no-cache add \
        py3-termcolor \
    # - hdf5
    && apk --no-cache add \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing/ \
        hdf5 \
    && apk --no-cache add --virtual .builddeps.edge \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing/ \
        hdf5-dev \
    && pip3 install h5py \
    ## install
    && pip3 install /tmp/tensorflow_pkg/tensorflow-${TENSORFLOW_VERSION}-cp36-cp36m-linux_x86_64.whl \
    ## clean 
    && apk del \
        .builddeps \
        .builddeps.edge \
    && find /usr/lib/python3.6 -name __pycache__ | xargs rm -r \
    && rm -rf \
        /root/.[acpw]* \
        /tmp/tensorflow* \
        /usr/local/bin/bazel

RUN set -x \
    ## ImportError: cannot import name 'create_prompt_application'
    && pip3 install ipython