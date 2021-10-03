#Practica 2. Unidad 3. Objetos básicos k8s

#Partimos del cluster local instalado en la práctica anterior.

#En general, vamos a aprovechar la definición de yaml de la forma imperativa con el comando aprendido en la clase 3 para crear nuestros propios yaml y desplegarlos en el cluster de forma declarativa.

#En primer lugar creamos el namespace sobre el que vamos a trabajar
#Obtenemos la estructura del yaml
uk create ns unit3 --dry-run=client -o yaml
#apiVersion: v1
#kind: Namespace
#metadata:
#  creationTimestamp: null
#  name: unit3
#spec: {}
#status: {}

#Creamos un yaml con los valores anteriores
vim namespace.yml
#Desplegamos el yaml en nuestro cluster de forma declarativa
uk apply -f namespace.yml
#namespace/unit3 created
#Comprobamos que se ha desplegado correctamente
uk get ns
#NAME              STATUS   AGE
#kube-system       Active   7d9h
#kube-public       Active   7d9h
#kube-node-lease   Active   7d9h
#default           Active   7d9h
#ingress           Active   7d9h
#unit3             Active   6s

#A continuación creamos un deployment en el namespace anteriormente y con la imagen indicada
#Obtenemos la estructura del yaml
uk create deployment k8s4arch-hotels --image=ghcr.io/go-elevate/k8s4arch-hotels:monolith --dry-run=client -o yaml
#apiVersion: apps/v1
#kind: Deployment
#metadata:
#  creationTimestamp: null
#  labels:
#    app: k8s4arch-hotels
#  name: k8s4arch-hotels
#spec:
#  replicas: 1
#  selector:
#    matchLabels:
#      app: k8s4arch-hotels
#  strategy: {}
#  template:
#    metadata:
#      creationTimestamp: null
#      labels:
#        app: k8s4arch-hotels
#    spec:
#      containers:
#      - image: ghcr.io/go-elevate/k8s4arch-hotels:monolith
#        name: k8s4arch-hotels
#        resources: {}
#status: {}

#Partiendo del template anterior modificaremos algunos valores y añadiremos algunos parámetros para cumplir con los atributos de calidad: alta disponibilidad, elasticidad y tolerancia a fallos.
vim deployment.yml
#.spec.replicas==3 Aumentaremos el número de replicas a 3. En este caso al utilizar un único nodo local de microk8s se desplegaran en el mismo nodo, sin embargo en un ejemplo real en el que tendremos como mínimo 3 nodos cada una de las replicas se desplegará en uno de los nodos.
#.spec.strategy.type==RollingUpdate Estableceremos una estrategia de despliegue mediante actualización continua y configuraremos sus valores:
#.spec.strategy.rollingUpdate.maxSurge==1 Con este valor configuramos el número máximo de pods que puede haber por encima del número deseado.
#.spec.strategy.rollingUpdate.maxUnavailable==0 Con este valor definimos el número máximo de pods que pueden estar no disponibles en el despliegue.
#Con los valores anteriores en un nuevo despligue los pods anteriores solo van a terminar cuando los nuevos estén running.

#Con los cambios anteriores desplegamos el deployment de forma declarativa
uk apply -f deployment.yml -n unit3
#deployment.apps/k8s4arch-hotels created

#Comprobamos si se han desplegados los pods correctamente:
 uk get pods -n unit3
#NAME                              READY   STATUS    RESTARTS   AGE
#k8s4arch-hotels-89df8c6cc-klnlx   1/1     Running   0          12s
#k8s4arch-hotels-89df8c6cc-gvvnt   1/1     Running   0          12s
#k8s4arch-hotels-89df8c6cc-9j7pr   1/1     Running   0          12s

#Con un describe del deployment podemos comprobar los valores configurados
uk describe deployment k8s4arch-hotels -n unit3
#Name:                   k8s4arch-hotels
#Namespace:              unit3
#CreationTimestamp:      Sun, 03 Oct 2021 09:07:28 +0200
#Labels:                 app=k8s4arch-hotels
#Annotations:            deployment.kubernetes.io/revision: 1
#Selector:               app=k8s4arch-hotels
#Replicas:               3 desired | 3 updated | 3 total | 3 available | 0 unavailable
#StrategyType:           RollingUpdate
#MinReadySeconds:        0
#RollingUpdateStrategy:  0 max unavailable, 1 max surge
#Pod Template:
#  Labels:  app=k8s4arch-hotels
#  Containers:
#   k8s4arch-hotels:
#    Image:        ghcr.io/go-elevate/k8s4arch-hotels:monolith
#    Port:         <none>
#    Host Port:    <none>
#    Environment:  <none>
#    Mounts:       <none>
#  Volumes:        <none>
#Conditions:
#  Type           Status  Reason
#  ----           ------  ------
#  Available      True    MinimumReplicasAvailable
#  Progressing    True    NewReplicaSetAvailable
#OldReplicaSets:  <none>
#NewReplicaSet:   k8s4arch-hotels-89df8c6cc (3/3 replicas created)
#Events:
#  Type    Reason             Age   From                   Message
#  ----    ------             ----  ----                   -------
#  Normal  ScalingReplicaSet  32m   deployment-controller  Scaled up replica set k8s4arch-hotels-89df8c6cc to 3

#En el describe también podemos ver valores no configurados como Port, Host Port, Environment, Mounts y Volumens, estos últimos al tratarse de una aplicación monolítica y tal y como nos describen consta en la imagen docker de todos los componentes de la solución y no se conecta a nada externo. De igual forma para un correcto autoescalado de la aplicación habría que añadir request al contenedor y configurar el horizontal pod autoescaler (HPA). Tal y como está configurado ahora mismo habría que escalar manualmente o bien modificando el yaml de despliegue o de la siguiente forma:
uk scale --replicas=4 deploy/k8s4arch-hotels -n unit3
#deployment.apps/k8s4arch-hotels scaled
#Lo comprobamos:
uk get pods -n unit3
#NAME                              READY   STATUS    RESTARTS   AGE
#k8s4arch-hotels-89df8c6cc-klnlx   1/1     Running   0          49m
#k8s4arch-hotels-89df8c6cc-gvvnt   1/1     Running   0          49m
#k8s4arch-hotels-89df8c6cc-9j7pr   1/1     Running   0          49m
#k8s4arch-hotels-89df8c6cc-5hf9w   1/1     Running   0          29s

#Por último, en el dashboard de microk8s podemos ver el estado de los pods creados. En la imagen adjunta se puede ver una captura del mismo.
