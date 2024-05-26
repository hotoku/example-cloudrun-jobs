GCP_REGION := asia-northeast1
JOB_NAME := clrun-example
REPO_NAME := dtl001
IMAGE_NAME := clrun-example
IMAGE_PATH := $(GCP_REGION)-docker.pkg.dev/$(PROJECT_ID)/$(REPO_NAME)/$(IMAGE_NAME)


.PHONY: image
image: commit-hash create-repository
	$(eval IMAGE_TAG := $(shell echo $(COMMIT_HASH) | cut -c -7))
	$(eval DB_PATH := $(shell basename $(DTL001_DB_PATH)))
	if [ "$(BUILD_PLACE)" = "local" ]; then \
		docker build -t $(IMAGE_PATH):$(IMAGE_TAG) --build-arg "SHORT_SHA=$(IMAGE_TAG)" .; \
		docker push $(IMAGE_PATH):$(IMAGE_TAG); \
		docker tag $(IMAGE_PATH):$(IMAGE_TAG) dtl001:latest; \
	else \
		gcloud builds submit \
	    --region=us-central1 \
	    --config=cloudbuild.yaml \
		--substitutions=SHORT_SHA=$(IMAGE_TAG),_IMAGE_NAME=$(IMAGE_NAME),_REPO_NAME=$(REPO_NAME),_GCP_REGION=$(GCP_REGION); \
	fi


.PHONY: create-repository
create-repository:
	if ! gcloud artifacts repositories describe --location=$(GCP_REGION) $(REPO_NAME) > /dev/null 2>&1; then \
		gcloud artifacts repositories create $(REPO_NAME) \
			--repository-format=docker \
			--location=$(GCP_REGION) \
			--description="Repository for $(IMAGE_NAME) images."; \
	fi

.PHONY: commit-hash
commit-hash: tree-clean
	$(eval COMMIT_HASH := $(shell git rev-parse HEAD | head -n1))


.PHONY: tree-clean
tree-clean:
	@if [ $$(git status -s | wc -l) -ge 1 ]; then echo "Error: local tree is dirty."; false; fi	

.PHONY: deploy
deploy: image
	gcloud run jobs deploy $(JOB_NAME) \
		--region=$(GCP_REGION) \
        --image=$(IMAGE_PATH):$(IMAGE_TAG) \
		--parallelism=20 \
		--tasks=1000

.PHONY: execute
execute:
	gcloud run jobs execute $(JOB_NAME) \
		--region=$(GCP_REGION) \
		--wait \
		--tasks=21 \
		--args=$(shell date +%Y%m%d%H%M%S)

