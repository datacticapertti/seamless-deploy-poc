.PHONY: setup deploy-initial-active deploy-smoke upgrade-active clean deepclean query-active query-smoke images

setup:
	command -v kubectl || (echo "Install kubectl first, see https://kubernetes.io/docs/tasks/tools/install-kubectl/" && exit 1)
	minikube start || (echo "Install minikube first, see https://kubernetes.io/docs/tasks/tools/install-minikube/" && exit 1)
	@echo 'To get docker images into minikube run the command:'
	@echo '  eval $$(minikube docker-env)'

deploy-initial-active:
	kubectl apply -f manifests/frontend-active-initial.yaml
	kubectl apply -f manifests/backend-v1.yaml

deploy-smoke:
	kubectl apply -f manifests/frontend-smoke.yaml
	kubectl apply -f manifests/backend-v2.yaml

upgrade-active:
	kubectl apply -f manifests/frontend-active-upgrade.yaml

clean:
	kubectl delete -f manifests/frontend-active-initial.yaml || true
	kubectl delete -f manifests/frontend-smoke.yaml || true
	kubectl delete -f manifests/backend-v1.yaml || true
	kubectl delete -f manifests/backend-v2.yaml || true

deepclean:
	minikube delete

query-active:
	curl $$(minikube service frontend-active --url)

query-smoke:
	curl $$(minikube service frontend-smoke --url)

images:
	cd images; make all
