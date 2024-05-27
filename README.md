# Cloud Run Jobs の parallelism の検証

- 最大のインスタンス数のベースが、region ごとに quota 制限がある
  - CPU の数・メモリの使用料を増やすと、その分だけインスタンス数の上限が下がる
- deploy 時に、parallelism を設定しておく。tasks の値以上にはできないので、tasks に適当な値を設定する。
- execute 時に、tasks の値は調整可能。

deploy時に最大限に並列化するように指定(parallelismを指定しない or 0)して、execute時にtasksの数を大きくすると、そのタスクの数だけのコンテナを立ち上げようとする。この数が、GCPのquotaの制限を超えていると正常に実行されない。

```makefile
.PHONY: deploy
deploy: image
	gcloud run jobs deploy $(JOB_NAME) \
		--region=$(GCP_REGION) \
        --image=$(IMAGE_PATH):$(IMAGE_TAG) \
		--parallelism=100 \
		--tasks=1000

.PHONY: execute
execute:
	gcloud run jobs execute $(JOB_NAME) \
		--region=$(GCP_REGION) \
		--wait \
		--tasks=100 \
		--args=$(shell date +%Y%m%d%H%M%S)
```
