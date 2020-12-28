#!/bin/bash


echo "Starting up security proxy for mbartists and mbtracks core"

`npm bin`/solr-security-proxy --port 9090 --backendHost 127.0.0.1 --backendPort 8983 --validPaths "/solr/mbartists/select,/solr/mbtracks/select"

