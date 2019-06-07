# OpenShift Spark

Openshift Spark is dockerize application based on the Centos 7 image for deploying Apache Spark 2.4.2 cluster to OpenShift.

Apache Spark is a fast and general-purpose cluster computing system. It provides high-level APIs in Java, Scala, Python and R, and an optimized engine that supports general execution graphs.

[http://spark.apache.org/](http://spark.apache.org/)

OpenShift is an open source container application platform by [Red Hat](https://www.redhat.com) based on top of Docker containers and the Kubernetes container cluster manager.

[https://www.openshift.com/](https://www.openshift.com/)

> **Deployment time: 30 minutes**

## Usage

### Clone

Clone this repo to local machine.

```
$ git clone https://github.com/bodz1lla/openshift-spark.git
$ cd openshift-spark
```

### Build

Create a build config and start build a spark image.

```
$ oc create -f openshift/build-spark-base.yaml
$ oc create imagestream spark
$ oc start-build spark-2.4.2
```
When the build has finished, please check logs and status.

```
$ oc logs -f bc/spark-2.4.2
$ oc get pod
NAME                  READY     STATUS      RESTARTS   AGE
spark-2.4.2-1-build   0/1       Completed   0          6m
```

### Deploy

#### Spark Master

Create a deployment config and start master.

```
$ oc create -f openshift/deploy-spark-master.yaml
```

When master has started, please check logs and state "Running".

```
$ oc logs -f dc/spark-master
$ oc get pod
NAME                   READY     STATUS      RESTARTS   AGE
spark-2.4.2-1-build    0/1       Completed   0          4m
spark-master-1-mxlhj   1/1       Running     0          55s
```

Create a services and endpoints.

```
$ oc create -f openshift/service_spark_master.yaml
$ oc create -f openshift/service_spark_master_ui.yaml
```

Expose a service and create a route to allow external connections reach Spark by DNS name.

```
$ oc expose svc/spark-master-ui --name=spark-master-ui --port=8080

```
Check a route and try to access the Spark via Web browser or cURL.

```
$ oc get route spark-master-ui
$ curl -s http://${SPARK_MASTER_UI}
```

> If you'd like to configure secure HTTPS connection with selfsigned certificate using TLS edge termination.
>
> Please install "keytool" and generate a keystore, otherwise just skip this step and move to Spark Workers.

> ATTENTION: Replace a var=${SECRET_PASS} with password.

```
$ keytool -genkey -keyalg RSA -alias selfsigned -keystore keystore.jks -storepass ${SECRET_PASS} -validity 360 -keysize 2048
# Convert to pkcs12
$ keytool -importkeystore -srckeystore keystore.jks -destkeystore keystore.p12 -srcstoretype jks -deststoretype pkcs12
```

Once key has been created, open it with OpenSSL.

```
$ openssl pkcs12 -in keystore.p12 -nodes -password pass:${SECRET_PASS}

```

Copy certificate with private key that have been displayed and save in the notes.

Edit route and insert TLS configuration in the "spec:" collection,  behind the "port:" key as described below:

```
oc edit route spark-master-ui

---
spec:
  ...
  port:
    targetPort: 8080
  tls:
    certificate: |
      -----BEGIN CERTIFICATE-----
      ...
      -----END CERTIFICATE-----
    key: |
      -----BEGIN PRIVATE KEY-----
      ...
      -----END PRIVATE KEY-----
    termination: edge
    insecureEdgeTerminationPolicy: Redirect    
```

> Don't forget about YAML syntax and 2 space indent.

Check route and try to access via HTTPS.

```
$ oc get route spark-master-ui
$ curl -sk https://${SPARK_MASTER_UI}
```

#### Spark Workers

Create a deployment config and start workers.

> The default setup starts only 3 workers, you can change this in deploy-spark-worker.yaml file. Replace a value in the key "replicas:"

```
$ oc create -f openshift/deploy-spark-workers.yaml
```

Check logs and workers state "Running".
```
$ oc logs -f dc/spark-workers
$ oc get pods
NAME                    READY     STATUS      RESTARTS   AGE
spark-2.4.2-1-build     0/1       Completed   0          37m
spark-master-1-7xqdq    1/1       Running     0          34m
spark-workers-1-7tj9d   1/1       Running     0          5m
spark-workers-1-8fbh2   1/1       Running     0          5m
spark-workers-1-kfdcm   1/1       Running     0          5m
```

If you see the same output with all pods are "Running", it means you successfully has installed Spark cluster :)

## Launching Applications with spark-submit.

This section explains how to submit applications to the cluster remotely.

1. [Download Spark](https://spark.apache.org/downloads.html) release to local machine.

2. Check firewall settings and allow TCP connections to the node port 30077.  

> You don't need to change anything on the OpenShift server, a step above only applies to the external firewalls belong to AWS Security Groups, Data-Centers providers like Hetzner, etc.

> Current project runs with Spark version 2.4.2.

> It’s important that the Spark version running on the driver, master, and worker pods all match.

3. Try to run Python or Java example application on the cluster.

```
cd spark-2.4.2-bin-hadoop2.7

# Python
./bin/spark-submit \
  --master spark://${OPENSHIFT_CLUSTER_IP}:30077 --name myapp  \
  ${PWD}/examples/src/main/python/pi.py 10

# Java
./bin/spark-submit \
  --class org.apache.spark.examples.SparkPi \
  --master spark://${OPENSHIFT_CLUSTER_IP}:30077 \
  --name myapp \
  --deploy-mode client \
  --supervise \
  --executor-memory 4G \
  --total-executor-cores 100 \
  local://${PWD}/examples/jars/spark-examples_2.12-2.4.2.jar 10
```
If connection successful has been created to the cluster and you see the running application in Spark UI, it means you've completed testing.

Hope you enjoyed the setup and ready to launch new applications!

## Contributing

1. Fork it (https://github.com/bodz1lla/openshift-spark/fork)
2. Create your feature branch (git checkout -b feature/foobar)
3. Commit your changes (git commit -am 'Add some foobar')
4. Push to the branch (git push origin feature/foobar)
5. Create a new Pull Request

>Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## Authors

* [Bogdan Denysiuk](https://github.com/bodz1lla)

* [Wolfgang Renk](https://github.com/wrenkredhat)

## License

This project is licensed under the terms of the MIT license.

See [COPYING](https://github.com/bodz1lla/openshift-spark/blob/develop/LICENSE) to see the full text.

## Acknowledgments

* [The Apache Software Foundation](https://github.com/apache) - Apache Spark
* [Thomas Orozco](https://github.com/krallin) - init for containers [tini](https://github.com/krallin/tini)
* Veer Muchandi - video explanation - [OpenShift: Using SSL](https://www.youtube.com/watch?v=rpT5qwcL3bE)
