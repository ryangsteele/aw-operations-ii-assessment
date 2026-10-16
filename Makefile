CLUSTER_NAME := shortlink
IMAGE        := shortlink:0.1.0

.PHONY: cluster infra build deploy verify clean

## Create the local cluster and start LocalStack inside it (run once, before the timer)
cluster:
	kind create cluster --config kind/cluster.yaml
	kubectl apply -f k8s/infra/localstack.yaml
	kubectl -n infra rollout status deployment/localstack --timeout=300s
	@echo ""
	@echo "Cluster ready. LocalStack is answering on http://localhost:4566"

## Provision the AWS resources (against LocalStack)
infra:
	terraform -chdir=terraform init -input=false
	terraform -chdir=terraform apply -input=false -auto-approve

## Build the application image and load it into the cluster
build:
	docker build -t $(IMAGE) app
	kind load docker-image $(IMAGE) --name $(CLUSTER_NAME)

## Deploy the shortlink service
deploy:
	kubectl apply -k k8s/app
	@echo ""
	@echo "Deploy complete."

## Run the pipeline's verification gate
verify:
	./scripts/verify.sh

## Tear everything down
clean:
	kind delete cluster --name $(CLUSTER_NAME)
	rm -rf terraform/.terraform terraform/terraform.tfstate terraform/terraform.tfstate.backup terraform/.terraform.lock.hcl
