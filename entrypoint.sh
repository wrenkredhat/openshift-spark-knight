#!/bin/bash
#
# Copyright 2019 Red Hat
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
SPARK_CMD=$1
MASTER_URL=$2

set -ex

myuid=$(id -u)
mygid=$(id -g)

# turn off an error code
set +e
uidentry=$(getent passwd $myuid)
set -e

# Automatically provide a passwd file entry for the anonymous uid
if [ -z "$uidentry" ]; then
    echo "$myuid:x:$myuid:$mygid:anonymous uid:$SPARK_HOME:/bin/false" >> /etc/passwd
fi

case $SPARK_CMD in
    master)
      CMD=(
        "$SPARK_HOME/bin/spark-class"
        "org.apache.spark.deploy.master.Master"
      )
      ;;
    worker)
      CMD=(
        "$SPARK_HOME/bin/spark-class"
        "org.apache.spark.deploy.worker.Worker"
        $MASTER_URL
      )
      ;;
    *)
      echo "Unknown command: $SPARK_CMD" 1>&2
      exit 1
esac

exec /sbin/tini -s -- "${CMD[@]}"
