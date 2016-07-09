FROM postgres

RUN apt-get update \
&& apt-get install -y --no-install-recommends \
ca-certificates \
e2fslibs-dev \
gcc \
libssl-dev \
make \
wget \
zlib1g-dev \
&& wget --quiet https://www.tarsnap.com/download/tarsnap-autoconf-1.0.37.tgz \
&& echo "fa999413651b3bd994547a10ffe3127b4a85a88b1b9a253f2de798888718dbfa  tarsnap-autoconf-1.0.37.tgz" | sha256sum --check --strict --quiet \
&& tar -xzf tarsnap-autoconf-1.0.37.tgz \
&& cd tarsnap-autoconf-1.0.37 \
&& ./configure \
&& make install \
&& cd .. \
&& rm -rf tarsnap-autoconf-* \
&& apt-get -y remove --purge \
ca-certificates \
e2fslibs-dev \
gcc \
libssl-dev \
make \
wget \
zlib1g-dev \
&& apt-get -y autoremove \
&& rm -rf /var/lib/apt/lists/*

COPY pg_tarsnap /usr/local/bin

ENTRYPOINT ["pg_tarsnap"]

CMD ["backup"]
