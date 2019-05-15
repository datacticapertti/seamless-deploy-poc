.PHONY: all explicit-docker-host frontend backend

all: frontend backend

explicit-docker-host:
	@[ -n "$${DOCKER_HOST}" ] || (echo "Looks like you are using the localhost docker daemon. This is probably a mistake." && false)

frontend: explicit-docker-host
	(cd frontend; docker build -t frontend:v1 -f v1/Dockerfile .)
	(cd frontend; docker build -t frontend:v2 -f v2/Dockerfile .)

backend: explicit-docker-host
	(cd backend; docker build -t backend:v1 -f v1/Dockerfile .)
	(cd backend; docker build -t backend:v2 -f v2/Dockerfile .)
