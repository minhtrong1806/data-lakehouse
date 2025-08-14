#!/bin/bash

export JAVA_HOME="$(jrunscript -e 'java.lang.System.out.println(java.lang.System.getProperty("java.home"));')"
export DAGSTER_HOME=/opt/dagster

# spark
start-master.sh -p 7077 --webui-port 8061
start-worker.sh spark://spark:7077 --webui-port 8062
start-history-server.sh
start-thriftserver.sh --hiveconf hive.server2.thrift.port 10000 --hiveconf hive.server2.authentication NOSASL


cd /src/dbt_dagster
dagster dev -h 0.0.0.0 -p 3000 &

# Entrypoint, for example notebook, pyspark or spark-sql
if [[ $# -gt 0 ]] ; then
    eval "$1"
fi
