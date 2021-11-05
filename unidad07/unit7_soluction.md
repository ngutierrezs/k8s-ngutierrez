#Practica 6. Unidad 7. Networking y Seguridad en el cluster


##Parte1: Segmentando el monolito

Se compone de los siguientes ficheros yaml:

- deploy_backend.yml
- deploy_frontend.yml

Creamos dos deployments, uno para el backend y otro para el frontend. En ambos se utilizan las nuevas imágenes y lo configurado anteriormente: configmap, resources, initcontainer, etc.

Creamos de forma imperativa un nuevo namespace para la unidad:

```bash
uk create ns unit7
namespace/unit7 created
```
Utilizamos el mismo configmap de las practica anteriores y lo desplegamos en el nuevo namespace.

Desplegamos ambos manifiestos y comprobamos que se crean correctamente:

```bash
uk get pods -n unit7 --show-labels
NAME                                        READY   STATUS    RESTARTS       AGE   LABELS
k8s4arch-hotels-frontend-74d9d78967-djlv4   1/1     Running   1 (133m ago)   13h   app=k8s4arch-hotels-frontend,pod-template-hash=74d9d78967,tier=frontend,version=stable
k8s4arch-hotels-frontend-74d9d78967-8lkx5   1/1     Running   1 (133m ago)   13h   app=k8s4arch-hotels-frontend,pod-template-hash=74d9d78967,tier=frontend,version=stable
k8s4arch-hotels-frontend-74d9d78967-djv8q   1/1     Running   1 (133m ago)   13h   app=k8s4arch-hotels-frontend,pod-template-hash=74d9d78967,tier=frontend,version=stable
k8s4arch-hotels-backend-8596684dcb-wc4np    1/1     Running   0              56m   app=k8s4arch-hotels-backend,pod-template-hash=8596684dcb,tier=backend,version=stable
k8s4arch-hotels-backend-8596684dcb-l8fk2    1/1     Running   0              56m   app=k8s4arch-hotels-backend,pod-template-hash=8596684dcb,tier=backend,version=stable
k8s4arch-hotels-backend-8596684dcb-wrtpl    1/1     Running   0              55m   app=k8s4arch-hotels-backend,pod-template-hash=8596684dcb,tier=backend,version=stable
```

En el frontend se configura la variable de entorno:

HOTELS_API_HOST=http://api-hotels.internal.itrip.io

##Parte2: Liberando la solución a los usuarios

Se compone de los siguientes ficheros yaml:

- service_backend.yml
- service_frontend.yml
- ingress_backend.yaml
- ingress_frontend.yaml

Para exponer al exterior la aplicación se generan un servicio del tipo ClusterIP y un ingress para cada uno, backend y frontend.

```bash
]$ uk get svc -n unit7
NAME           TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
backend-svc    ClusterIP   10.152.183.250   <none>        80/TCP    116m
frontend-svc   ClusterIP   10.152.183.196   <none>        80/TCP    115m

]$ uk get ingress -n unit7
NAME               CLASS    HOSTS                              ADDRESS     PORTS   AGE
frontend-ingress   <none>   awesome-hotels.internal.itrip.io   127.0.0.1   80      114m
backend-ingress    <none>   api-hotels.internal.itrip.io       127.0.0.1   80      114m
```
Nos cercioramos que está el ingress habilitado:

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
```
Incluimos los hosts en nuestro `/etc/hosts`, pero aún así no conseguimos acceder desde el navegador, nos da el error `ERR_CONNECTION_REFUSED`


##Parte3: Evitando accessos indeseados

Se compone del siguiente fichero yaml:

- netpolicy.yaml

Creamos una `NetworkPolicies` que impida el acceso a los pods de backend de cualquier otro pod que no sea el frontend, ingress policie. Y además por defecto denegamos el tráfico de salida.

```bash
]$ uk describe netpol backend -n unit7
Name:         backend
Namespace:    unit7
Created on:   2021-11-02 00:18:27 +0100 CET
Labels:       <none>
Annotations:  <none>
Spec:
  PodSelector:     app=k8s4arch-hotels-backend
  Allowing ingress traffic:
    To Port: <any> (traffic allowed to all ports)
    From:
      PodSelector: app=k8s4arch-hotels-frontend
  Allowing egress traffic:
    To Port: <any> (traffic allowed to all ports)
    To:
      PodSelector: <none>
  Policy Types: Ingress, Egress
```

Lo probamos pidiendo un curl desde un pod de backend y obteniendo respuesta, y desde un pod de otro namespace sin obtenerla:

```bash
]$ uk exec -ti nginx -- curl http://backend-svc.unit7.svc.cluster.local/hotels
kubectl exec [POD] [COMMAND] is DEPRECATED and will be removed in a future version. Use kubectl exec [POD] -- [COMMAND] instead.
curl: (7) Failed to connect to backend-svc.unit7.svc.cluster.local port 80: Connection timed out
command terminated with exit code 7
```

