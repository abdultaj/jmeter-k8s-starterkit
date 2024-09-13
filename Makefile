SHELL := /bin/bash
PHONY: create

PROJECT_NAME ?= bank-account-service
SERVICE ?= spark-master-two

create:
	kubectl create -R -f k8s/

create-tools:
	-kubectl create -R -f k8s/tool/
	-kubectl create -f k8s/metric-server.yaml

delete:
	kubectl delete -R -f k8s/

delete-tools:
	-kubectl delete -R -f k8s/tool/
	-kubectl delete -f k8s/metric-server.yaml

ssh-jmeter:
	kubectl exec -it $(kubectl get pod -o name --selector jmeter_mode=master) bash

build-jmeter:
	docker build -t jmeter/test -f Dockerfile .

dashboard-proxy:
	kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443

wiremock-expose:
	kubectl expose deployment wiremock --type=LoadBalancer --name=wiremock-ext

influx-expose:
	kubectl expose deployment influxdb --type=LoadBalancer --name=influx-ext

clean-project:
	-kubectl delete pods --field-selector status.phase=Failed -A
