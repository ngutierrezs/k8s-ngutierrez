#Practica 3. Unidad 4. Diseño de aplicaciones

##Parte 1: Etiquetas/anotaciones

Partimos del deployment de la practica de la unidad anterior. Ya teníamos una etiqueta:

```bash
 uk get pods -n unit3 --show-labels
NAME                              READY   STATUS    RESTARTS      AGE   LABELS
k8s4arch-hotels-89df8c6cc-9j7pr   1/1     Running   1 (85s ago)   9d    app=k8s4arch-hotels,pod-template-hash=89df8c6cc
k8s4arch-hotels-89df8c6cc-gvvnt   1/1     Running   1 (85s ago)   9d    app=k8s4arch-hotels,pod-template-hash=89df8c6cc
k8s4arch-hotels-89df8c6cc-klnlx   1/1     Running   1 (85s ago)   9d    app=k8s4arch-hotels,pod-template-hash=89df8c6cc
k8s4arch-hotels-89df8c6cc-5hf9w   1/1     Running   1 (85s ago)   9d    app=k8s4arch-hotels,pod-template-hash=89df8c6cc
```
Y añadimos otra: `type=monolith` que nos indica de que tipo es la aplicación. Para que el pod se etiquete con la label indicada es necesario añadirlo en los metadata del template del pod:

```bash
template:
    metadata:
      creationTimestamp: null
      labels:
        app: k8s4arch-hotels
        type: monolith
```

Aplicamos la nueva etiqueta:

```bash
uk apply -f deployment_parte1.yml -n unit3
deployment.apps/k8s4arch-hotels created
 uk get pods -n unit3 --show-labels
NAME                               READY   STATUS    RESTARTS   AGE   LABELS
k8s4arch-hotels-5b55d9876c-2ps99   1/1     Running   0          78s   app=k8s4arch-hotels,pod-template-hash=5b55d9876c,type=monolith
k8s4arch-hotels-5b55d9876c-qq264   1/1     Running   0          75s   app=k8s4arch-hotels,pod-template-hash=5b55d9876c,type=monolith
k8s4arch-hotels-5b55d9876c-qq6jb   1/1     Running   0          72s   app=k8s4arch-hotels,pod-template-hash=5b55d9876c,type=monolith
#También la podemos añadir manualmente
uk label pod k8s4arch-hotels-89df8c6cc-9j7pr type=monolith -n unit3
pod/k8s4arch-hotels-89df8c6cc-9j7pr labeled
[07:18:42 ngutierrez@NGS-Pro ~/Documents/cursok8s/k8s-ngutierrez/unidad04
]$ uk get pods -n unit3 --show-labels
NAME                              READY   STATUS    RESTARTS        AGE   LABELS
k8s4arch-hotels-89df8c6cc-gvvnt   1/1     Running   1 (3m28s ago)   9d    app=k8s4arch-hotels,pod-template-hash=89df8c6cc
k8s4arch-hotels-89df8c6cc-klnlx   1/1     Running   1 (3m28s ago)   9d    app=k8s4arch-hotels,pod-template-hash=89df8c6cc
k8s4arch-hotels-89df8c6cc-5hf9w   1/1     Running   1 (3m28s ago)   9d    app=k8s4arch-hotels,pod-template-hash=89df8c6cc
k8s4arch-hotels-89df8c6cc-9j7pr   1/1     Running   1 (3m28s ago)   9d    app=k8s4arch-hotels,pod-template-hash=89df8c6cc,type=monolith
```
##Parte 2: Estrategia de despliegue

Como ya hicimos en la práctica anterior mantenemos la estrategia de despliegue en RollingUpdate con el número máximo de pods no disponibles a 0 para garantizar la alta disponibilidad.

```bash
strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
```

Aplicamos la nueva versión:

```bash
]$ uk apply -f deployment_parte2y3.yml -n unit3
deployment.apps/k8s4arch-hotels configured
[07:55:24 ngutierrez@NGS-Pro ~/Documents/cursok8s/k8s-ngutierrez/unidad04
]$ uk get pods -n unit3 --show-labels
NAME                               READY   STATUS    RESTARTS   AGE   LABELS
k8s4arch-hotels-57c8b496bb-kp966   1/1     Running   0          20s   app=k8s4arch-hotels,pod-template-hash=57c8b496bb,type=monolith,version=v2
k8s4arch-hotels-57c8b496bb-ksc4v   1/1     Running   0          17s   app=k8s4arch-hotels,pod-template-hash=57c8b496bb,type=monolith,version=v2
k8s4arch-hotels-57c8b496bb-7ldlq   1/1     Running   0          14s   app=k8s4arch-hotels,pod-template-hash=57c8b496bb,type=monolith,version=v2
```

##Parte 3: Probes

Tal y como nos dice el enunciado del ejercicio añadimos una readiness probe para que compruebe la salud de la aplicación antes de redirigir el tráfico:

```bash
spec:
      containers:
      - image: ghcr.io/go-elevate/k8s4arch-hotels:monolith-v2
        name: k8s4arch-hotels
        resources: {}
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 3
          periodSeconds: 3
```

Una vez desplegado podemos comprobar que se está ejecutando en los logs del pod:

```bash
uk logs -f k8s4arch-hotels-66c6fccf4-x255f -n unit3
/docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
/docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
/docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
10-listen-on-ipv6-by-default.sh: Getting the checksum of /etc/nginx/conf.d/default.conf
10-listen-on-ipv6-by-default.sh: Enabled listen on IPv6 in /etc/nginx/conf.d/default.conf
/docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh
/docker-entrypoint.sh: Configuration complete; ready for start up
192.168.64.3 - - [14/Oct/2021:04:57:25 +0000] "GET / HTTP/1.1" 200 2156 "-" "kube-probe/1.22+" "-"
192.168.64.3 - - [14/Oct/2021:04:57:28 +0000] "GET / HTTP/1.1" 200 2156 "-" "kube-probe/1.22+" "-"
192.168.64.3 - - [14/Oct/2021:04:57:31 +0000] "GET / HTTP/1.1" 200 2156 "-" "kube-probe/1.22+" "-"
192.168.64.3 - - [14/Oct/2021:04:57:34 +0000] "GET / HTTP/1.1" 200 2156 "-" "kube-probe/1.22+" "-"
192.168.64.3 - - [14/Oct/2021:04:57:37 +0000] "GET / HTTP/1.1" 200 2156 "-" "kube-probe/1.22+" "-"
192.168.64.3 - - [14/Oct/2021:04:57:40 +0000] "GET / HTTP/1.1" 200 2156 "-" "kube-probe/1.22+" "-"
192.168.64.3 - - [14/Oct/2021:04:57:43 +0000] "GET / HTTP/1.1" 200 2156 "-" "kube-probe/1.22+" "-"
192.168.64.3 - - [14/Oct/2021:04:57:46 +0000] "GET / HTTP/1.1" 200 2156 "-" "kube-probe/1.22+" "-"
192.168.64.3 - - [14/Oct/2021:04:57:49 +0000] "GET / HTTP/1.1" 200 2156 "-" "kube-probe/1.22+" "-"
192.168.64.3 - - [14/Oct/2021:04:57:52 +0000] "GET / HTTP/1.1" 200 2156 "-" "kube-probe/1.22+" "-"
192.168.64.3 - - [14/Oct/2021:04:57:55 +0000] "GET / HTTP/1.1" 200 2156 "-" "kube-probe/1.22+" "-"
192.168.64.3 - - [14/Oct/2021:04:57:58 +0000] "GET / HTTP/1.1" 200 2156 "-" "kube-probe/1.22+" "-"
192.168.64.3 - - [14/Oct/2021:04:58:01 +0000] "GET / HTTP/1.1" 200 2156 "-" "kube-probe/1.22+" "-"
192.168.64.3 - - [14/Oct/2021:04:58:04 +0000] "GET / HTTP/1.1" 200 2156 "-" "kube-probe/1.22+" "-"
192.168.64.3 - - [14/Oct/2021:04:58:07 +0000] "GET / HTTP/1.1" 200 2156 "-" "kube-probe/1.22+" "-"
192.168.64.3 - - [14/Oct/2021:04:58:10 +0000] "GET / HTTP/1.1" 200 2156 "-" "kube-probe/1.22+" "-"
192.168.64.3 - - [14/Oct/2021:04:58:13 +0000] "GET / HTTP/1.1" 200 2156 "-" "kube-probe/1.22+" "-"
192.168.64.3 - - [14/Oct/2021:04:58:16 +0000] "GET / HTTP/1.1" 200 2156 "-" "kube-probe/1.22+" "-"
192.168.64.3 - - [14/Oct/2021:04:58:19 +0000] "GET / HTTP/1.1" 200 2156 "-" "kube-probe/1.22+" "-"
192.168.64.3 - - [14/Oct/2021:04:58:22 +0000] "GET / HTTP/1.1" 200 2156 "-" "kube-probe/1.22+" "-"
192.168.64.3 - - [14/Oct/2021:04:58:25 +0000] "GET / HTTP/1.1" 200 2156 "-" "kube-probe/1.22+" "-"
192.168.64.3 - - [14/Oct/2021:04:58:28 +0000] "GET / HTTP/1.1" 200 2156 "-" "kube-probe/1.22+" "-"
```
##Parte 4: Aplicaciones efímeras. Jobs y cronjobs

En este caso y como es un ambiente bajo prueba generamos otro namespace para ello (unit4). En este namespace vamos a tener un cronjob que ejecutará un job a las 2AM con el reporte de aplicación:

```bash
apiVersion: batch/v1
kind: CronJob
metadata:
  creationTimestamp: null
  name: k8s4arch-hotels-diary-report
  namespace: unit4
spec:
  jobTemplate:
    metadata:
      creationTimestamp: null
      name: k8s4arch-hotels-diary-report
    spec:
      template:
        metadata:
          creationTimestamp: null
        spec:
          containers:
          - image: ghcr.io/go-elevate/k8s4arch-hotels-backend:slim
            name: k8s4arch-hotels-diary-report
            command: ["python", "report.py"]
            resources: {}
          restartPolicy: OnFailure
  schedule: 0 2 * * *
status: {}

```

Para probar que funciona correctamente modificamos el schedule, comprobamos que se ha ejecutado y comprobamos los logs del pod creado:

```bash
]$ uk get pods -n unit4
NAME                                             READY   STATUS      RESTARTS      AGE
k8s4arch-hotels-57c8b496bb-thzgx                 1/1     Running     1 (45m ago)   23h
k8s4arch-hotels-57c8b496bb-bw8qp                 1/1     Running     1 (45m ago)   23h
k8s4arch-hotels-57c8b496bb-sdn2t                 1/1     Running     1 (45m ago)   23h
k8s4arch-hotels-diary-report-27236488--1-hz7df   0/1     Completed   0             6s

 uk logs k8s4arch-hotels-diary-report-27236488--1-hz7df -n unit4
Hotel Entre Cielos had 15 reservations. Hotel is at 93.75% of its full capacity
Hotel Casa Turquesa had 8 reservations. Hotel is at 88.88888888888889% of its full capacity
Hotel Hotel Huacalera had 25 reservations. Hotel is at 78.125% of its full capacity
Hotel Luma Casa de Montaña had 4 reservations. Hotel is at 50.0% of its full capacity
Hotel Alto Atacama had 7 reservations. Hotel is at 16.666666666666664% of its full capacity

```

