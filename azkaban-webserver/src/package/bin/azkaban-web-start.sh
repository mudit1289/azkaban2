#!/bin/bash

azkaban_dir=$(dirname $0)/..

if [[ -z "$tmpdir" ]]; then
tmpdir=/tmp
fi

for file in $azkaban_dir/lib/*.jar;
do
  CLASSPATH=$CLASSPATH:$file
done

for file in $azkaban_dir/extlib/*.jar;
do
  CLASSPATH=$CLASSPATH:$file
done

for file in $azkaban_dir/plugins/*/*.jar;
do
  CLASSPATH=$CLASSPATH:$file
done

if [ "$HADOOP_HOME" != "" ]; then
        echo "Using Hadoop from $HADOOP_HOME"
        CLASSPATH=$CLASSPATH:$HADOOP_HOME/conf:$HADOOP_HOME/*
        JAVA_LIB_PATH="-Djava.library.path=$HADOOP_HOME/lib/native/Linux-amd64-64"
else
        echo "Error: HADOOP_HOME is not set. Hadoop job types will not run properly."
fi

if [ "$HIVE_HOME" != "" ]; then
        echo "Using Hive from $HIVE_HOME"
        CLASSPATH=$CLASSPATH:$HIVE_HOME/conf:$HIVE_HOME/lib/*
fi

echo $azkaban_dir;
echo $CLASSPATH;

executorport=`cat $azkaban_dir/conf/azkaban.properties | grep executor.port | cut -d = -f 2`
jmxremote_port=`expr $executorport + 2000 `

JMX_REMOTE_OPTS="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=$jmxremote_port -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false"

LOG_DIR="/var/log/flipkart/fk-bigfoot-azkaban"

GC_LOGGING_OPTIONS=" -XX:+PrintGCApplicationStoppedTime -XX:+PrintGC -XX:+PrintGCDateStamps -XX:+PrintGCDetails \
                     -XX:+PrintGCTimeStamps -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=15 \
                     -XX:GCLogFileSize=128K"

start_time=`date "+%Y%m%d_%H_%M_%S"`
serverpath=`pwd`

if [ -z $AZKABAN_OPTS ]; then
  AZKABAN_OPTS="-Xmx10G $GC_LOGGING_OPTIONS -Dlogfile.path=$LOG_DIR -Xloggc:$LOG_DIR/gc_webserver.log.$start_time"
fi
AZKABAN_OPTS="$AZKABAN_OPTS -server $JMX_REMOTE_OPTS -Djava.io.tmpdir=$tmpdir -Dexecutorport=$executorport -Dserverpath=$serverpath"

java $AZKABAN_OPTS $JAVA_LIB_PATH -cp $CLASSPATH azkaban.webapp.AzkabanWebServer -conf $azkaban_dir/conf $@ &

echo $! > $azkaban_dir/currentpid

