#!/bin/bash

#This script creates the cryptographic key material needed for BGPsec. You must parse the amount of routers required + 1 for BGPSECIO.

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <number_of_routers>"
  exit 1
fi

NUM_ROUTERS="$1"
START_ASN=64600
OUTDIR="key_setup"
ASNFILE="$OUTDIR/topology_asns"
KEYDIR="$OUTDIR/testbed_keys"

mkdir -p "$KEYDIR"
> "$ASNFILE"

# Step 1: Generate ASN list
for ((i=0; i<NUM_ROUTERS; i++)); do
  echo $((START_ASN + i)) >> "$ASNFILE"
done

echo "[INFO] Generated $ASNFILE with $NUM_ROUTERS ASNs."

# Step 2: Create CA certificate
openssl ecparam -name prime256v1 -genkey -out "$OUTDIR/ca.pem"
openssl req -new -x509 -key "$OUTDIR/ca.pem" -out "$OUTDIR/ca.cert" -days 3650 -sha256 -subj "/CN=local"

# Step 3: Generate certs and keys for each ASN
while read -r asn; do
  echo "[INFO] Processing ASN $asn"

  openssl ecparam -genkey -name prime256v1 -out "$OUTDIR/as${asn}_bgpsec.pem"
  asn_hex="$(printf '0000%04X' "$asn")"
  SUBJ="/CN=ROUTER-$asn_hex"

  openssl req -new -key "$OUTDIR/as${asn}_bgpsec.pem" -out "$OUTDIR/as${asn}_bgpsec.csr" --config bgpsec_openssl.cnf -subj "$SUBJ"
  openssl req -inform PEM -outform DER -in "$OUTDIR/as${asn}_bgpsec.csr" -out "$OUTDIR/as${asn}_bgpsec_der.csr"

  openssl ec -in "$OUTDIR/as${asn}_bgpsec.pem" -pubout -out "$OUTDIR/as${asn}_bgpsec.key"

  SKI=$(openssl asn1parse -in "$OUTDIR/as${asn}_bgpsec.key" -strparse 23 -noout -out - | openssl dgst -sha1 | awk '{print toupper($2)}')
  dir2=${SKI:0:2}
  dir4=${SKI:2:4}
  part_SKI=${SKI:6}
  mkdir -p "$KEYDIR/$dir2/$dir4"

  openssl ec -inform pem -in "$OUTDIR/as${asn}_bgpsec.pem" -outform der -out "$OUTDIR/$part_SKI.der"
  openssl pkey -pubin -in "$OUTDIR/as${asn}_bgpsec.key" -outform DER -pubout -out "$OUTDIR/$asn.$SKI.0.key"

  openssl x509 -req -in "$OUTDIR/as${asn}_bgpsec.csr" -CA "$OUTDIR/ca.cert" -CAkey "$OUTDIR/ca.pem" -out "$OUTDIR/${part_SKI}_pem.cert" -days 365 -sha256
  openssl x509 -outform der -in "$OUTDIR/${part_SKI}_pem.cert" -out "$OUTDIR/$part_SKI.cert"

  cp "$OUTDIR/$part_SKI.der" "$KEYDIR/$dir2/$dir4/"
  mv "$OUTDIR/as${asn}_bgpsec_der.csr" "$KEYDIR/$dir2/$dir4/$part_SKI.csr"
  mv "$OUTDIR/$part_SKI.cert" "$KEYDIR/$dir2/$dir4"

  echo "$asn-SKI: $SKI" | tee -a "$KEYDIR/priv-ski-list.txt" "$KEYDIR/ski-list.txt" > /dev/null

done < "$ASNFILE"

echo "[INFO] Certificate + SKI generation complete."
cat "$KEYDIR/ski-list.txt"

# Cleanup intermediate files
rm -f "$OUTDIR"/*_bgpsec.pem "$OUTDIR"/*_bgpsec.csr "$OUTDIR"/*_bgpsec.key "$OUTDIR"/*_pem.cert

echo "[DONE] Everything stored in: $OUTDIR"
