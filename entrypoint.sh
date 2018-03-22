#!/bin/sh

set -ex

# Check if samba is setup
if [ -f /var/lib/samba/.setup ]; then
    exec samba -i -s /var/lib/samba/private/smb.conf < /dev/null
fi

# Require $SAMBA_REALM to be set
: "${SAMBA_REALM:?SAMBA_REALM needs to be set}"

# If $SAMBA_PASSWORD is not set, generate a password
SAMBA_PASSWORD=${SAMBA_PASSWORD:-`(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c20; echo) 2>/dev/null`}
echo "Samba password set to: $SAMBA_PASSWORD"

# Populate $SAMBA_OPTIONS
SAMBA_OPTIONS=${SAMBA_OPTIONS:-}

[ -n "$SAMBA_DOMAIN" ] \
    && SAMBA_OPTIONS="$SAMBA_OPTIONS --domain=$SAMBA_DOMAIN" \
    || SAMBA_OPTIONS="$SAMBA_OPTIONS --domain=${SAMBA_REALM%%.*}"

[ -n "$SAMBA_HOST_IP" ] && SAMBA_OPTIONS="$SAMBA_OPTIONS --host-ip=$SAMBA_HOST_IP"

# Provision domain
rm -f /etc/samba/smb.conf
rm -rf /var/lib/samba/*
samba-tool domain provision \
    --use-rfc2307 \
    --realm=${SAMBA_REALM} \
    --adminpass=${SAMBA_PASSWORD} \
    --server-role=dc \
    --dns-backend=SAMBA_INTERNAL \
    $SAMBA_OPTIONS \
    --option="bind interfaces only"=yes

# Move smb.conf
mv /etc/samba/smb.conf /var/lib/samba/private/smb.conf

# Update dns-forwarder if required
[ -n "$SAMBA_DNS_FORWARDER" ] \
    && sed -i "s/dns forwarder = .*/dns forwarder = $SAMBA_DNS_FORWARDER/" /var/lib/samba/private/smb.conf

# Mark samba as setup
touch /var/lib/samba/.setup

# Setup only?
[ -n "$SAMBA_SETUP_ONLY" ] && exit 127 || :

