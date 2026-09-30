#!/bin/sh

set -e

pg_restore \
  --exit-on-error \
  --no-owner \
  --no-privileges \
  -U "$POSTGRES_USER" \
  -d "$POSTGRES_DB" \
  /docker-entrypoint-initdb.d/bkt_quitanda.dump