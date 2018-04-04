FROM debian:buster
MAINTAINER ps@ct.heise.de
# inspired by pitkley/samba-ad-dc
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install --no-install-recommends -y \
        samba samba-dsdb-modules samba-vfs-modules winbind \
	dos2unix ldb-tools \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Add services
COPY ./entrypoint.sh /entrypoint.sh

VOLUME ["/var/lib/samba"]

ENTRYPOINT ["/entrypoint.sh"]
