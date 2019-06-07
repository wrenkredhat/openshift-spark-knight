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
# ------------------------------------------------------------------------
#
# This is a Dockerfile for the spark:2.4.2 image.

# Default values of build arguments.
FROM centos:latest

ARG SPARK_VERSION="2.4.2"
ARG SPARK_DOWNLOAD_URL="https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop2.7.tgz"
ARG SPARK_DOWNLOAD_MD5SUM="cbea5f41e1c622de9a480fe4e1f48bd3"

# Default values of environment variables.
ENV \
    SPARK_HOME="/opt/spark" \
    PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${SPARK_HOME}/bin" \
    TINI_VERSION="v0.18.0"

# Install required RPMs and ensure that the packages were installed
    yum clean all -y && \
    rm -rf /var/cache/yum


# Download Spark and verify md5sum of file

# Extract the Spark

# Set root group (0) permissions to the Spark directory and files.
# By default, OpenShift Enterprise runs containers using an arbitrarily assigned user ID.
# Directories and files that may be written to by processes in the image should be owned by the root group and be read/writable by that group.


# Add our init script
ADD startsiab.sh /opt/startsiab.sh
# Fix up the Reverse coloring
ADD black-on-white.css /usr/share/shellinabox/black-on-white.css
# Add nano syntax highlighting for Dockerfiles
ADD dockerfile.nanorc /usr/share/nano/dockerfile.nanorc
# Add nano syntax highlighting for JS
ADD javascript.nanorc /usr/share/nano/javascript.nanorc
# Enable nano syntax highlighting
ADD nanorc /tmp/nanorc

# Install EPEL
# Install our developer tools (tmux, ansible, nano, vim, bash-completion, wget)
# Free up some space
# Install oc
# Add our developer user
# Bring in nano's user config
# Give nano's user config the correct ownership
# Set the default password for our 'developer' user
# Randomize root's password
# Be sure to remove login's lock file
RUN echo "" && \
    cat /opt/siab.logo.txt && \
    echo "=== Installing EPEL ===" && \
    yum install -y http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/epel-release-7-11.noarch.rpm && \
    echo "\n=== Installing developer tools ===" && \
    yum install -y jq vim screen which hostname passwd tmux nano wget git bash-completion openssl shellinabox util-linux expect --enablerepo=epel && \
    yum clean all && \
    cd /tmp/ && \
    echo "\n=== Installing oc ===" && \
    wget https://github.com/openshift/origin/releases/download/v3.10.0/openshift-origin-client-tools-v3.10.0-dd10d17-linux-64bit.tar.gz && \
    ls -lah /tmp/ && \
    echo "\n=== Untar'ing 'oc' ===" && \
    tar zxvf /tmp/openshift-origin-client-tools-v3.10.0-dd10d17-linux-64bit.tar.gz && \
    echo "\n=== Copying 'oc' ===" && \
    mv -v /tmp/openshift-origin-client-tools-v3.10.0-dd10d17-linux-64bit/oc /usr/local/bin/ && \
    echo "\n=== Installing 'developer' user ===" && \
    useradd -u 1001 developer -m && \
    mkdir -pv /home/developer/bin /home/developer/tmp && \
    echo "\n=== Bringing in nano's user config ===" && \
    mv -v /tmp/nanorc /home/developer/.nanorc && \
    echo "\n=== Giving nano's user config the correct ownership ===" && \
    chown -R 1001:1001 /home/developer && \
    echo "\n=== Setting the default password for our 'developer' user ===" && \
    ( echo "developer" | passwd developer --stdin ) && \
    echo "\n=== Randomizing root's password ===" && \
    ( cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 128 | head -n 1 | passwd root --stdin ) && \
    echo "\n=== Removing login's lock file ===" && \
    rm -f /var/run/nologin && \
    echo "*** Done building siab container ***" && \
    cat /opt/siab.logo.txt && \
    yum install -y java-1.8.0-openjdk wget && \
    cd /opt; wget -q --progress=bar ${SPARK_DOWNLOAD_URL} -O spark-${SPARK_VERSION}-bin-hadoop2.7.tgz && \
    cd /opt; tar --no-same-owner -zxf spark-${SPARK_VERSION}-bin-hadoop2.7.tgz && \
    rm -fr spark-${SPARK_VERSION}-bin-hadoop2.7.tgz && \
    ln -s /opt/spark-${SPARK_VERSION}-bin-hadoop2.7 /opt/spark && \
    chgrp -R 1001:1001 ${SPARK_HOME} && chmod -R g+rw ${SPARK_HOME} && \
    echo "${SPARK_DOWNLOAD_MD5SUM} spark-${SPARK_VERSION}-bin-hadoop2.7.tgz" | md5sum -c -

# shellinabox will listen on 8080
EXPOSE 8080

# Run as developer
USER 1001

# Run our init script
CMD /opt/startsiab.sh
