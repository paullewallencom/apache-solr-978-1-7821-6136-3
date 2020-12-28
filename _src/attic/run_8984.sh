#!/bin/sh
cd ..
java -Xms512M -Xmx1024M -Dfile.encoding=UTF8 -Dsolr.solr.home=cores -Dsolr.slave.enable=true -Dsolr.data.dir=../../cores_data/data8984 -Djetty.port=8984 -Djetty.home=solr -Djetty.logs=solr/logs -jar solr/start.jar