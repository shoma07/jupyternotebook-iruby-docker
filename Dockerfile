FROM jupyter/all-spark-notebook

USER root

RUN mkdir -p /usr/local/etc \
    && { \
         echo 'install: --no-document'; \
         echo 'update: --no-document'; \
    } >> /usr/local/etc/gemrc

ENV RUBY_MAJOR 2.6
ENV RUBY_VERSION 2.6.3
ENV RUBY_DOWNLOAD_SHA256 11a83f85c03d3f0fc9b8a9b6cad1b2674f26c5aaa43ba858d4b0fcc2b54171e1

RUN set -ex \
    \
    && buildDeps=' \
         bison \
         dpkg-dev \
         libgdbm-dev \
         autoconf \ 
         ruby \
         zlib1g-dev \
         libssl-dev \
         libtool \
         libffi-dev \
    ' \
    && apt-get update \
    && apt-get install -y --no-install-recommends $buildDeps libzmq3-dev libczmq-dev gnuplot \
    && rm -rf /var/lib/apt/lists/* \
    \
    && wget -O ruby.tar.xz "https://cache.ruby-lang.org/pub/ruby/${RUBY_MAJOR%-rc}/ruby-$RUBY_VERSION.tar.xz" \
    && echo "$RUBY_DOWNLOAD_SHA256 *ruby.tar.xz" | sha256sum -c - \
    \
    && mkdir -p /usr/src/ruby \
    && tar -xJf ruby.tar.xz -C /usr/src/ruby --strip-components=1 \
    && rm ruby.tar.xz \
    \
    && cd /usr/src/ruby \
    \
    && { \
         echo '#define ENABLE_PATH_CHECK 0'; \
         echo; \
         cat file.c; \
    } > file.c.new \
    && mv file.c.new file.c \
    \
    && autoconf \
    && gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
    && ./configure \
         --build="$gnuArch" \
         --disable-install-doc \
         --enable-shared \
    && make -j "$(nproc)" \
    && make install \
    \
    && gem install cztop daru nyaplot gnuplotrb \
    && gem install iruby --pre \
    && iruby register --force \
    \
    && apt-get purge -y --auto-remove $buildDeps \
    && cd / \
    && rm -r /usr/src/ruby \
    && ruby --version && gem --version && bundle --version

ENV GEM_HOME /usr/local/bundle
ENV BUNDLE_PATH="$GEM_HOME" \
    BUNDLE_SILENCE_ROOT_WARNING=1 \
    BUNDLE_APP_CONFIG="$GEM_HOME"
ENV PATH $GEM_HOME/bin:$BUNDLE_PATH/gems/bin:$PATH
RUN mkdir -p "$GEM_HOME" && chmod 777 "$GEM_HOME"

USER $NB_UID
