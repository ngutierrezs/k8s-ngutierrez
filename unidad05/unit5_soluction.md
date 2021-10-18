#Practica 4. Unidad 5. Manejo de Configuración

##Parte 1: Configmap - Secrets 

Creamos un configmap dado que las variables no son usuarios ni contraseñas que necesiten ser ofuscadas:

```bash

uk get cm -n unit5
NAME               DATA   AGE
kube-root-ca.crt   1      10m
db-config          2      10s
```
Creamos un deployment teniendo en cuenta:

- El configmap anterior
- La nueva imagen
- Lo etiquetamos con nuevas labels referidas al nuevo despliegue
- Utilizamos una estrategia de despliegue RollingUpdate 
- Configuramos el puerto donde se va a ejecutar la aplicación
- Configuramos las probes teniendo en cuenta el nuevo endpoint donde expone su healthcheck.

Retrasamos la Readiness probe 30s en el inicio y comprobamos que no está ready hasta pasado ese tiempo:

```bash
]$ uk get pods -n unit5
NAME                                       READY   STATUS    RESTARTS   AGE
k8s4arch-hotels-backend-768467bff5-6qzhw   0/1     Running   0          15s
k8s4arch-hotels-backend-768467bff5-drmw4   0/1     Running   0          15s
k8s4arch-hotels-backend-768467bff5-kqk26   0/1     Running   0          15s
[19:54:20 ngutierrez@NGS-Pro ~/Documents/cursok8s/k8s-ngutierrez/unidad05
]$ uk get pods -n unit5
NAME                                       READY   STATUS    RESTARTS   AGE
k8s4arch-hotels-backend-768467bff5-drmw4   1/1     Running   0          87s
k8s4arch-hotels-backend-768467bff5-kqk26   1/1     Running   0          87s
k8s4arch-hotels-backend-768467bff5-6qzhw   1/1     Running   0          87s
```
Comprobamos que se han aplicado las nuevas labels configuradas:
```bash
]$ uk get pods -n unit5 --show-labels
NAME                                       READY   STATUS    RESTARTS   AGE   LABELS
k8s4arch-hotels-backend-768467bff5-drmw4   1/1     Running   0          34m   app=k8s4arch-hotels-backend,pod-template-hash=768467bff5,tier=backend,version=slim
k8s4arch-hotels-backend-768467bff5-kqk26   1/1     Running   0          34m   app=k8s4arch-hotels-backend,pod-template-hash=768467bff5,tier=backend,version=slim
k8s4arch-hotels-backend-768467bff5-6qzhw   1/1     Running   0          34m   app=k8s4arch-hotels-backend,pod-template-hash=768467bff5,tier=backend,version=slim
```
Comprobamos que las variables configuradas en el configmap están disponibles en el pod:
```bash
uk exec -ti k8s4arch-hotels-backend-768467bff5-drmw4 env -n unit5 | grep DB
kubectl exec [POD] [COMMAND] is DEPRECATED and will be removed in a future version. Use kubectl exec [POD] -- [COMMAND] instead.
DB_TABLE=hotels
DB_PATH=/db/hotels.json
```
Hacemos un port forwarding al puerto del contenedor y comprobamos el status:

```bash
]$ uk port-forward k8s4arch-hotels-backend-768467bff5-drmw4 5000:5000 -n unit5
Forwarding from 127.0.0.1:5000 -> 5000
Forwarding from [::1]:5000 -> 5000
Handling connection for 5000
```
Nos devuelve `{"status":"UP"}`


##Parte 2: La app crashea

Utilizando el deployment de la parte anterior le añadimos resources necesarios para que la aplicación tenga recursos suficientes en el arranque y limites para el reinicio cuando sea necesario:

```bash
]$ uk describe pod k8s4arch-hotels-backend-7f664d8d6c-zff2s -n unit5
Name:         k8s4arch-hotels-backend-7f664d8d6c-zff2s
Namespace:    unit5
Priority:     0
Node:         microk8s-vm/192.168.64.3
Start Time:   Mon, 18 Oct 2021 20:41:16 +0200
Labels:       app=k8s4arch-hotels-backend
              pod-template-hash=7f664d8d6c
              tier=backend
              version=slim
Annotations:  cni.projectcalico.org/podIP: 10.1.254.112/32
              cni.projectcalico.org/podIPs: 10.1.254.112/32
Status:       Running
IP:           10.1.254.112
IPs:
  IP:           10.1.254.112
Controlled By:  ReplicaSet/k8s4arch-hotels-backend-7f664d8d6c
Containers:
  k8s4arch-hotels:
    Container ID:   containerd://2765b541600484d1a6e99655aa0c41ee6af88a3ef112fde22f428d7858ac7a3f
    Image:          ghcr.io/go-elevate/k8s4arch-hotels-backend:slim
    Image ID:       ghcr.io/go-elevate/k8s4arch-hotels-backend@sha256:a9688019bb846491b25115de2d68f78589f907e6f6a7e9632f49269139822fbb
    Port:           5000/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Mon, 18 Oct 2021 20:41:18 +0200
    Ready:          True
    Restart Count:  0
    Limits:
      cpu:     1
      memory:  2Gi
    Requests:
      cpu:      500m
      memory:   1Gi
    Liveness:   tcp-socket :5000 delay=30s timeout=1s period=3s #success=1 #failure=3
    Readiness:  http-get http://:5000/status delay=30s timeout=1s period=3s #success=1 #failure=3
    Environment Variables from:
      db-config   ConfigMap  Optional: false
```
Con un top podemos comprobar los recursos reales que está utilizando:

```bash
]$ uk top pods -n unit5
W1018 20:44:16.582518   31255 top_pod.go:140] Using json format to get metrics. Next release will switch to protocol-buffers, switch early by passing --use-protocol-buffers flag
NAME                                       CPU(cores)   MEMORY(bytes)
k8s4arch-hotels-backend-7f664d8d6c-6zvjw   2m           20Mi
k8s4arch-hotels-backend-7f664d8d6c-k96bb   2m           20Mi
k8s4arch-hotels-backend-7f664d8d6c-zff2s   2m           20Mi
```

