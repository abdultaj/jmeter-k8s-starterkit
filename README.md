# JMeter k8s

This is a repository from which you can start testing service when injecting load from a kubernetes cluster.

You will find inside it the necessary to organize and run your performance scenario. There is also a node monitoring tool which will monitor all your injection nodes. As well an embeded live monitoring with InfluxDB and Grafana


## Features


| Feature     | Supported  | Comment    |
|-------------|:----------:|-------------
| Flexibility at run time      |    Yes     | With .env file (threads, duration, host) |
| Distributed testing      |     No     | Virtually unlimited with auto-scaling     |
| JMeter Plugin support |    Yes     | Modules are installed at run time by scanning the JMX needs      |
| JMeter Module support |    Yes     | JMeter include controller are supported if *path* is just the name of the file in the *Include Controler*
| JMeter CSV support |    Yes     | CSV files are splitted prior to launch the test and unique pieces copied to each pods, in the JMeter scenario, just put the name of the file in the *path* field |
| Node auto-scaling |     No     | By requesting ressources at deployment time, the cluster will scale automatically if needed |
| Reporting |    Yes     | The JMeter report is generated at the end of the test inside the master pod if the -r flag is used in the start_test.sh|
| Live monitoring |    Yes     | An InfluxDB instance and a Grafana are available in the stack |
| Report persistance |    Yes     | A persistence volume is used to store the reports and results |
| Injector nodes monitoring |    Yes     | Even if autoscaling, a Daemon Set will deploy a telegraf instance and persist the monitoring data to InfluxDB. A board is available in Grafana to show the Telegraf monitoring
| Multi thread group support | Not really | You can add multi thread groups, but if you want to use JMeter properties (like threads etc..) you need to add them in the .env and update the start_test.sh to update the "user_param" variable to add the desired variables |
| Mocking service |    Yes     | A deployment of Wiremock is done inside the cluster, the mappings are done inside the wiremock configmap. Also an horizontal pod autoscaler have been added
| JVM Monitoring |    Yes     | JMeter and Wiremock are both Java application. They have been packaged with Jolokia and Telegraf and are monitored
| Pre built Grafana Dashboards |    Yes     | 4 Grafana dashboards are shipped with the starter kit. Node monitoring, Kubernetes ressources monitoring, JVM monitoring and JMeter result dashboard.
| Ressource friendly |    Yes     | JMeter is deployed as batch job inside the cluster. Thus at the end  of the execution, pods are deleted and ressources freed

## Getting started

Prerequisites :
- A kubernetes cluster (of course) (amd64 and arm64 architecture are supported)
- kubectl installed and a usable context to work with
- (Optionnal) A JMeter scenario (the default one attack wiremock)

### 1. Preparing the repository

You need to put your JMeter project inside the `scenario` folder, inside a folder named after the JMX (without the extension).
Put your CSV file inside the `dataset` folder, child of `scenario`
Put your JMeter modules (include controlers) inside the `module` folder, child of `scenario`

`dataset`and `module`are in `scenario` and not below inside the `<project>` folder because, in some cases, you can have multiple JMeter projects that are sharing the JMeter modules (that's the goal of using modules after all).


*Below a visual representation of the file structure*

```bash
+-- scenario
|   +-- dataset
|   +-- module
|   +-- my-scenario
|       +-- my-scenario.jmx
|    
```

### 2. Deploying the Stack

If you want to deploy in AWS, please refer to [aws folder](./aws/)
#### From this repository

`make build-project` 

this will create an image locally `jmeter/test:latest` for jmeter which will also load the test script to run as a cronJob start_test.sh

`make create`

This will deploy all the needed applications :

- JMeter master
- Telegraf operator to automatically monitor the specified applications
- Telegraf as a DaemonSet on all the nodes
- InfluxDB to store the date (with a 5GB volume in a PVC)
- Grafana with a LB services and 4 included dashboard
- Wiremock

### 3. Starting the test locally

Once you have create the containers with `make create` the job is scheduled to run every two minutes to run the test with command in jmeter-master.yaml file

`/bin/bash /opt/start_test.sh -j my-scenario.jmx -r`
to load scenario file from git  `/bin/bash /opt/start_test.sh -j my-scenario.jmx -s git -o abdultaj/jmeter-k8s-starterkit -v main -p scenario/my-scenario/my-scenario.jmx -r`

Usage :
```sh
   -j <filename.jmx>
   -s <source> git
   -o <repo> owner and repo of github
   -v <revision> git version
   -p <path> path to the file
   -r flag to enable report generation at the end of the test
```

### 4. Clean Job
Once the job has finished jmeter will be in Not Ready state which will be then deleted by another job to free resources

### 4. Access Grafana Dashboard
```
localhost: 443
user: admin
password: XhXUdmQ576H6e7
```

### 5. Jmeter Env
```
GITHUB_TOKEN - to get scenario files from github and lives in side k8 secrets
EMAIL_PASSWORD - for sending jtl log of the test to email and lives in side k8 secrets
HOST - global request host config 
PORT - global request port config 
PROTOCOL - global request protocol config
THREADS - global request thread numbers
DURATION - global request duration
RAMPUP - global rampup test
```

### 6. Delete All Pods
`make delete`

