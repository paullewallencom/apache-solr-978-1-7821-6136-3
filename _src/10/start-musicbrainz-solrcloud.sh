#!/bin/bash

numServers=$1
numShards=$2

solrVersion=4.8.1

baseJettyPort=8983
zkPort=`expr $baseJettyPort + 1000`
echo "ZooKeeper running on port $zkPort"
baseStopPort=6572

die () {
    echo >&2 "$@"
    exit 1
}

[ "$#" -eq 2 ] || die "2 arguments required, $# provided, usage: solrcloud-start-musicbrainz.sh {numServers} {numShards}"

mkdir -p solrcloud-working-dir/example

rm -rf solrcloud-working-dir/example*

cd solrcloud-working-dir
if [ ! -e "solr-$solrVersion.zip" ]; then
  curl -O http://solrenterprisesearchserver.s3.amazonaws.com/downloads/solr-$solrVersion.zip
  #curl -O http://apache.mirrors.pair.com/lucene/solr/$solrVersion/solr-$solrVersion.zip  
fi
if [ ! -e "solr-$solrVersion" ]; then
  unzip solr-$solrVersion.zip
fi


cp -rf solr-$solrVersion/example  ./example

rm -r example/solr-webapp/*
unzip example/webapps/solr.war -d example/solr-webapp/webapp

cp -rf solr-$solrVersion/contrib/velocity/lib ./example/solr/lib
cp -f solr-$solrVersion/dist/solr-velocity-$solrVersion.jar ./example/solr/lib/

for (( i=1; i <= $numServers; i++ ))
do
 echo "create example$i"
 cp -r -f example example$i
done

# collection1 has to exist to have the GUI work.
#java -classpath "example1/solr-webapp/webapp/WEB-INF/lib/*:example/lib/ext/*" org.apache.solr.cloud.ZkCLI -cmd upconfig -confdir ../../cores/mbtype/conf -confname collection1 -zkhost 127.0.0.1:$zkPort -solrhome example1/solr -runzk $baseJettyPort

# mbtypes is actually the configuration that we want to load to create mbartists, mbtracks, and mbreleases from.
# you can use the zkcli.sh script instead.
java -classpath "example1/solr-webapp/webapp/WEB-INF/lib/*:example/lib/ext/*" org.apache.solr.cloud.ZkCLI -cmd upconfig -confdir ../../configsets/mbtype/conf -confname mbtypes -zkhost 127.0.0.1:$zkPort -solrhome example1/solr -runzk $baseJettyPort

echo "starting example1 on $baseJettyPort"
cd example1
java -Xmx1g -DzkRun -DnumShards=$numShards -DSTOP.PORT=$baseStopPort -Djetty.port=$baseJettyPort -DSTOP.KEY=key -jar start.jar 1>example1.log 2>&1 &


for (( i=2; i <= $numServers; i++ ))
do
  cd ../example$i
  stopPort=`expr $baseStopPort + $i`
  jettyPort=`expr $baseJettyPort + $i`
  echo "starting example$i on $jettyPort"
  java -Xmx1g -Djetty.port=$jettyPort -DzkHost=localhost:$zkPort -DnumShards=1 -DSTOP.PORT=$stopPort -DSTOP.KEY=key -jar start.jar 1>example$i.log 2>&1 &
done

echo "monitoring start of example1"
until $(curl --output /dev/null --silent --head --fail http://localhost:${baseJettyPort}/solr); do
  printf '.'
  sleep 1
done

for (( i=2; i <= $numServers; i++ ))
do
  echo "monitoring start of example$i"
  jettyPort=`expr $baseJettyPort + $i`
  until $(curl --output /dev/null --silent --head --fail http://localhost:${jettyPort}/solr); do
    printf '.'
    sleep 1
  done
  print ""
done

echo "To create a core run \"curl 'http://localhost:8983/solr/admin/collections?action=CREATE&name=mbartists&numShards=$numShards&replicationFactor=2&maxShardsPerNode=3&collection.configName=mbtypes'\""
echo "Then, from the example directory, run 'ant index:mbartists"

