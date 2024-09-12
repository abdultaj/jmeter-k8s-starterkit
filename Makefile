SHELL := /bin/bash
PHONY: create

PROJECT_NAME ?= bank-account-service
SERVICE ?= spark-master-two

create:
	kubectl create -R -f k8s/

delete:
	kubectl delete -R -f k8s/

ssh-jmeter:
	kubectl exec -it $(kubectl get pod -o name --selector jmeter_mode=master) bash

build-jmeter:
	docker build -t jmeter/test -f Dockerfile .

dashboard-proxy:
	kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443



clean-project:
	-kubectl delete pods --field-selector status.phase=Failed -A
