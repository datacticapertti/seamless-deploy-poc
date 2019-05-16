# Seamless Deployment POC

Proof of concept for seamless deployment of a multi tier application.

The application consists of two kinds of pods, frontend pods and
backend pods. A frontend pod receives a http request, contacts a
backend pod, and returns a result that identifies the version of both
pods.

There can be two deployments of the application side by side, an
active one and a smoke test one. The active deployment can then be
incrementally upgraded to the same version as the smoke one. The
initial deployment consists of version v1 of both pod kinds. The smoke
deployment consists of version v2 of the pods.

There is no smart scripting, everything is done with hard coded
kubernetes manifests.

## Pod version compatibility

This example deals with a situation where no assumptions are made
about the compatibility of pods across versions. Version v1 frontend
pods may only contact version v1 backend pods, and ditto for version
v2. This necessitates strict separation of backend pods using
separate kubernetes services. The frontend pods also need to be
parameterized so that they know which backend pods they should use.

If backward compatibility can be assumed, i.e. backend v2 pods are
compatible with frontend v1 pods, a much simpler strategy can be
used. First version v1 is installed as the smoke test application,
then the smoke test backend is updated to v2 and the application is
tested, and finally the frontend is updated to v2 and the application
is tested again. If this succeeds, the same procedure can be applied
to the active application.

## Preliminaries

You need to have kubectl and minikube installed. If you have neither,
install them and things will just work. If you already have kubectl,
you need to configure it to talk to the minikube kubernetes
cluster. Minikube installation might do this.

* https://kubernetes.io/docs/tasks/tools/install-kubectl/
* https://kubernetes.io/docs/tasks/tools/install-minikube/
* https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/

## Set up a local kubernetes cluster

Once you have minikube, set up the kubernetes cluster with

    $ make setup

## Build docker images

Minikube uses a docker daemon running inside a virtual machine. You
need to set a few environment variables to get images built in the
minikube docker daemon:

    $ eval $(minikube docker-env)

To build the images used in the example, use

    $ make images

## Deploy the initial active version of the application

The initial version is deployed with

    $ make deploy-initial-active

This starts up five frontend pods and five backend pods. The active
version of the application is accessed via kubernetes service
*frontend-active*, and the backend pods are accessed via kubernetes
service *backend-v1*. You can see these with kubectl:

    $ kubectl get pod
    NAME                               READY   STATUS    RESTARTS   AGE
    backend-v1-8697b97b5b-8vcxc        1/1     Running   0          19s
    backend-v1-8697b97b5b-krhcj        1/1     Running   0          19s
    backend-v1-8697b97b5b-p6b7g        1/1     Running   0          19s
    backend-v1-8697b97b5b-vvs64        1/1     Running   0          19s
    backend-v1-8697b97b5b-z54pr        1/1     Running   0          19s
    frontend-active-5fc66c8777-5zlxx   1/1     Running   0          19s
    frontend-active-5fc66c8777-gf5qm   1/1     Running   0          19s
    frontend-active-5fc66c8777-l74cd   1/1     Running   0          19s
    frontend-active-5fc66c8777-nkqp7   1/1     Running   0          19s
    frontend-active-5fc66c8777-nljqj   1/1     Running   0          19s

    $ kubectl get service
    NAME              TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
    backend-v1        LoadBalancer   10.111.79.30    <pending>     80:31988/TCP   73s
    frontend-active   LoadBalancer   10.96.111.158   <pending>     80:31312/TCP   73s
    kubernetes        ClusterIP      10.96.0.1       <none>        443/TCP        7h13m

In a real setup, *backend-v1* would be ClusterIP instead of
LoadBalancer, but LoadBalancer is convenient for poking around. To verify the
application is running, you can do

    $ make query-active
    curl $(minikube service frontend-active --url)
    frontend:v1 - backend:v1

## Deploy a new version for smoke test

A new version can now be installed alongside the active one for
smoking. This involves two kubernetes deployments.

* Deployment of a new backend. The new backend pods are distinguished
  from the old ones by a version label, and they are accessed via a
  separate kubernetes service *backend-v2*. This deployment and its pods will
  eventually be taken into active service.

* Deployment of a new fronted for smoke testing. The new frontend pods
  are distinguished from the old ones by the label *deploy-stage*. In
  contrast to the backend pods, the deployment of the new frontend is
  temporary, and the new version is taken in use by modifying the
  existing active frontend deployment.

The smoke test version is deployed with

    $ make deploy-smoke

Now the two versions of the application are running side by side. The
active version works as before:

    $ make query-active
    curl $(minikube service frontend-active --url)
    frontend:v1 - backend:v1

The smoke test version can be queried likewise, and it shows the new
versions of the pods:

    $ make query-smoke
    curl $(minikube service frontend-smoke --url)
    frontend:v2 - backend:v2

## Upgrade the active application

Now that we are satisfied that the new version of the application
works as intended, we can roll it out. This is done with

    $ make upgrade-active

This updates the docker image used in the deployment
*frontend-active*. Kubernetes notices the change, and starts updating
the pods belonging to *frontend-active*. The update process is slowed
down in the example by specifying that a pod can be taken in use only
after 30 seconds after creation. Pod termination and creation can be
observed using kubectl:

    $ kubectl get pod -w
    NAME                               READY   STATUS    RESTARTS   AGE
    backend-v1-8697b97b5b-8vcxc        1/1     Running   0          18h
    backend-v1-8697b97b5b-krhcj        1/1     Running   0          18h
    backend-v1-8697b97b5b-p6b7g        1/1     Running   0          18h
    backend-v1-8697b97b5b-vvs64        1/1     Running   0          18h
    backend-v1-8697b97b5b-z54pr        1/1     Running   0          18h
    backend-v2-7fd7f68b74-6fjnk        1/1     Running   0          6m3s
    backend-v2-7fd7f68b74-k2qr6        1/1     Running   0          6m3s
    backend-v2-7fd7f68b74-kj8df        1/1     Running   0          6m3s
    backend-v2-7fd7f68b74-lrznx        1/1     Running   0          6m3s
    backend-v2-7fd7f68b74-m2jnd        1/1     Running   0          6m3s
    frontend-active-5fc66c8777-gf5qm   1/1     Running   0          18h
    frontend-active-5fc66c8777-l74cd   1/1     Running   0          18h
    frontend-active-5fc66c8777-nkqp7   1/1     Running   0          18h
    frontend-active-5fc66c8777-nljqj   1/1     Running   0          18h
    frontend-active-846b8c54c7-hrgm9   1/1     Running   0          13s
    frontend-active-846b8c54c7-vqq9b   1/1     Running   0          12s
    frontend-smoke-657ddc674b-6vqz4    1/1     Running   0          6m4s
    frontend-smoke-657ddc674b-9qqnv    1/1     Running   0          6m3s
    frontend-smoke-657ddc674b-q9tsl    1/1     Running   0          6m4s
    frontend-smoke-657ddc674b-tghjh    1/1     Running   0          6m3s
    frontend-smoke-657ddc674b-vvmd4    1/1     Running   0          6m4s
    frontend-active-5fc66c8777-l74cd   1/1     Terminating   0          18h
    frontend-active-5fc66c8777-gf5qm   1/1     Terminating   0          18h
    frontend-active-846b8c54c7-568mg   0/1     Pending       0          0s
    frontend-active-846b8c54c7-568mg   0/1     Pending       0          0s
    frontend-active-846b8c54c7-xjqwq   0/1     Pending       0          0s
    frontend-active-846b8c54c7-xjqwq   0/1     Pending       0          0s
    frontend-active-846b8c54c7-568mg   0/1     ContainerCreating   0          0s
    frontend-active-846b8c54c7-xjqwq   0/1     ContainerCreating   0          0s
    frontend-active-846b8c54c7-xjqwq   1/1     Running             0          3s
    frontend-active-846b8c54c7-568mg   1/1     Running             0          3s
    frontend-active-5fc66c8777-gf5qm   0/1     Terminating         0          18h
    frontend-active-5fc66c8777-l74cd   0/1     Terminating         0          18h
    frontend-active-5fc66c8777-gf5qm   0/1     Terminating         0          18h
    frontend-active-5fc66c8777-gf5qm   0/1     Terminating         0          18h
    frontend-active-5fc66c8777-l74cd   0/1     Terminating         0          18h
    frontend-active-5fc66c8777-l74cd   0/1     Terminating         0          18h

Kubectl can also give information about the rollout status:

    $ kubectl rollout status deploy/frontend-active
    Waiting for deployment "frontend-active" rollout to finish: 4 of 5 updated replicas are available...
    deployment "frontend-active" successfully rolled out

The git repo contains a script that polls the active application once
a second. its output shows how responses initially come from the old
version of the application, and are gradually replaced by responses
from the new version:

    $ ./scripts/poll-active 
    frontend:v1 - backend:v1
    frontend:v1 - backend:v1
    frontend:v1 - backend:v1
    frontend:v1 - backend:v1
    frontend:v2 - backend:v2
    frontend:v2 - backend:v2
    frontend:v1 - backend:v1
    frontend:v1 - backend:v1
    frontend:v1 - backend:v1
    frontend:v2 - backend:v2
    frontend:v2 - backend:v2
    frontend:v2 - backend:v2
    frontend:v1 - backend:v1
    frontend:v2 - backend:v2
    frontend:v2 - backend:v2
    frontend:v2 - backend:v2
    frontend:v2 - backend:v2
    frontend:v2 - backend:v2

Assuming that enough resources are available, there should not be any
significant reduction in the availability of the application. The
backend v2 is already operational at the time frontend v2 pods start
to appear in the active application.

## Scale down the smoke test version and old backend

The application is now running version v2, so the old backend can be
scaled down or deleted. Similarly, the smoke test frontend can be
scaled down as well.

    $ kubectl scale deployment backend-v1 --replicas=0
    $ kubectl scale deployment frontend-smoke --replicas=0

## Cleanup

The deployments, services, and pods can be removed from minikube with

    $ make clean

To remove the minikube cluster completely you can do

    $ make deepclean
