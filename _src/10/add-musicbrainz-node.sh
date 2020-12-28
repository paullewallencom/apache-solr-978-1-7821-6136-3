#!/bin/bash

newNodeJettyPort=$1

baseJettyPort=8983
zkPort=`expr $baseJettyPort + 1000`
echo "ZooKeeper running on port $zkPort"
baseStopPort=6572

die () {
    echo >&2 "$@"
    exit 1
}

[ "$#" -eq 1 ] || die "1 argument required, $# provided, usage: add-musicbrainz-node.sh {newNodeJettyPort}}"

cd solrcloud-working-dir

echo "create example$newNodeJettyPort"
cp -r -f example example$newNodeJettyPort

echo "starting jetty on $newNodeJettyPort"
cd example$newNodeJettyPort
java -Xmx1g -DzkRun -DzkHost=localhost:$zkPort -Djetty.port=$newNodeJettyPort -DSTOP.KEY=key -jar start.jar 1>example1.log 2>&1 &

echo "monitoring start of example$newNodeJettyPort"
until $(curl --output /dev/null --silent --head --fail http://localhost:${newNodeJettyPort}/solr); do
  printf '.'
  sleep 1
done
print ""

echo "To add a replica to this node run \"curl 'http://localhost:8983/solr/admin/collections?action=ADDREPLICA&collection=mbartists&shard=shard1&node=10.0.1.200:${newNodeJettyPort}_solr'\""
echo "Note: put in your local LAN ip address where the command has 10.0.1.200"

