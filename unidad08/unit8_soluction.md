#Practica 7. Unidad 8. Aplicaciones Stateful


Se compone de los siguientes ficheros yaml:

- pvc_local.yml
- deploy_backend.yml

En primer lugar habilitamos el addons `storage`:

```bash
microk8s status
microk8s is running
high-availability: no
  datastore master nodes: 127.0.0.1:19001
  datastore standby nodes: none
addons:
  enabled:
    dashboard            # The Kubernetes dashboard
    dns                  # CoreDNS
    ha-cluster           # Configure high availability on the current node
    ingress              # Ingress controller for external access
    metallb              # Loadbalancer for your Kubernetes cluster
    metrics-server       # K8s Metrics Server for API access to service metrics
    storage              # Storage class; allocates storage from host directory
```
Y comprobamos que ha generado una `storage class`

```bash
]$ uk get sc
NAME                          PROVISIONER            RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
microk8s-hostpath (default)   microk8s.io/hostpath   Delete          Immediate           false                  84s
```
Utilizamos el mismo namespace de la unidad 7 ya que solo cambiaremos el deployment del backen y mantendremos el resto de configuraciones.

Desplegamos el manifiesto del `Persitence Volumen Claim` y comprobamos que se ha aplicado correctamente:

```bash
uk get pvc -n unit7
NAME          STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS        AGE
backend-pvc   Bound    pvc-5abf9612-2412-46c5-8dc1-b50ed8d38daf   1G         RWO            microk8s-hostpath   3m53s
```
A continuación desplegamos el deployment del backend modificado añadiendo el PVC creado anteriormente y comprobamos que se ha desplegado correctamente:

```bash
]$ uk get pod -n unit7
NAME                                        READY   STATUS        RESTARTS      AGE
k8s4arch-hotels-frontend-545b4b6d65-jrhf9   1/1     Running       1 (14h ago)   3d5h
k8s4arch-hotels-frontend-545b4b6d65-czkk8   1/1     Running       1 (14h ago)   3d5h
k8s4arch-hotels-frontend-545b4b6d65-lzv9f   1/1     Running       1 (14h ago)   3d5h
k8s4arch-hotels-backend-68789959c9-tr22t    1/1     Running       0             80s
k8s4arch-hotels-backend-68789959c9-ns4v7    1/1     Running       0             59s
k8s4arch-hotels-backend-68789959c9-gw68g    1/1     Running       0             42s
```
En el describe del deployment podemos ver como el nuevo volumen configurado:

```bash
uk describe deployment k8s4arch-hotels-backend -n unit7
Name:                   k8s4arch-hotels-backend
Namespace:              unit7
CreationTimestamp:      Mon, 01 Nov 2021 11:04:02 +0100
Labels:                 app=k8s4arch-hotels-backend
Annotations:            deployment.kubernetes.io/revision: 5
Selector:               app=k8s4arch-hotels-backend
Replicas:               3 desired | 3 updated | 3 total | 3 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  0 max unavailable, 1 max surge
Pod Template:
  Labels:  app=k8s4arch-hotels-backend
           tier=backend
           version=stable
  Init Containers:
   db-migrations:
    Image:      ghcr.io/go-elevate/k8s4arch-hotels-backend:stable
    Port:       <none>
    Host Port:  <none>
    Command:
      python
    Args:
      migrations.py
    Environment Variables from:
      db-config   ConfigMap  Optional: false
    Environment:  <none>
    Mounts:
      /db from db (rw)
  Containers:
   k8s4arch-hotels-backend:
    Image:      ghcr.io/go-elevate/k8s4arch-hotels-backend:stable
    Port:       5000/TCP
    Host Port:  0/TCP
    Limits:
      cpu:     200m
      memory:  500Mi
    Requests:
      cpu:      100m
      memory:   250Mi
    Liveness:   tcp-socket :5000 delay=10s timeout=1s period=3s #success=1 #failure=3
    Readiness:  http-get http://:5000/status delay=10s timeout=1s period=3s #success=1 #failure=3
    Environment Variables from:
      db-config   ConfigMap  Optional: false
    Environment:  <none>
    Mounts:
      /db from db (rw)
  Volumes:
   db:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  backend-pvc
    ReadOnly:   false
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  <none>
NewReplicaSet:   k8s4arch-hotels-backend-68789959c9 (3/3 replicas created)
Events:
  Type    Reason             Age    From                   Message
  ----    ------             ----   ----                   -------
  Normal  ScalingReplicaSet  10m    deployment-controller  Scaled up replica set k8s4arch-hotels-backend-68789959c9 to 1
  Normal  ScalingReplicaSet  10m    deployment-controller  Scaled down replica set k8s4arch-hotels-backend-8596684dcb to 2
  Normal  ScalingReplicaSet  10m    deployment-controller  Scaled up replica set k8s4arch-hotels-backend-68789959c9 to 2
  Normal  ScalingReplicaSet  10m    deployment-controller  Scaled down replica set k8s4arch-hotels-backend-8596684dcb to 1
  Normal  ScalingReplicaSet  10m    deployment-controller  Scaled up replica set k8s4arch-hotels-backend-68789959c9 to 3
  Normal  ScalingReplicaSet  9m48s  deployment-controller  Scaled down replica set k8s4arch-hotels-backend-8596684dcb to 0
```

En el commit se incluyen el resto de yaml para tener la definición completa.
