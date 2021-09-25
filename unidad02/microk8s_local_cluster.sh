#Practica 1. Unidad 2. Instalacion cluster kubernetes

#Instalacion local con microk8s en Mac (Seguimos la guia https://microk8s.io/docs/install-alternatives

#Descargamos el instalador con brew
brew install ubuntu/microk8s/microk8s
#Lanzamos el instalador
microk8s install
#Comprobamos el estado y vemos los addons disponibles
microk8s status
#Instalamos los addons que nos pueden ser de utilidad
microk8s enable dashboard dns ingress metrics-server
#dashboard -->  para ver el estado del cluster.
#dns -->  como resolucion de nombres de dominio del cluster.
#metrics-server --> Necesario para ver las métricas del cluster y que funcione el autoescalado. 
#Se instalarán como pod en el namespace kube-system
#ingress --> Permitira el acceso externo al cluster. Se instala en un namespace propio del mismo nombre.

#Comprobamos el cluster instalado inicialmente

microk8s kubectl version

#Client Version: version.Info{Major:"1", Minor:"21", GitVersion:"v1.21.2", GitCommit:"092fbfbf53427de67cac1e9fa54aaa09a28371d7", GitTreeState:"clean", BuildDate:"2021-06-16T12:59:11Z", GoVersion:"go1.16.5", Compiler:"gc", Platform:"darwin/amd64"}
#Server Version: version.Info{Major:"1", Minor:"22+", GitVersion:"v1.22.2-3+a4bd0397e1cb5e", GitCommit:"a4bd0397e1cb5e638a6a6464f759114ee2250ea1", GitTreeState:"clean", BuildDate:"2021-09-16T00:00:16Z", GoVersion:"go1.16.7", Compiler:"gc", Platform:"linux/amd64"}

microk8s kubectl get nodes -o wide

#NAME          STATUS   ROLES    AGE   VERSION                    INTERNAL-IP    EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION       CONTAINER-RUNTIME
#microk8s-vm   Ready    <none>   23m   v1.22.2-3+a4bd0397e1cb5e   192.168.64.3   <none>        Ubuntu 18.04.6 LTS   4.15.0-158-generic   containerd://1.5.2

microk8s kubectl get namespaces

#NAME              STATUS   AGE
#kube-system       Active   8m13s
#kube-public       Active   8m13s
#kube-node-lease   Active   8m13s
#default           Active   8m12s
#ingress           Active   3m38s

microk8s kubectl get pods --all-namespaces

#NAMESPACE     NAME                                         READY   STATUS    RESTARTS   AGE
#kube-system   calico-node-2w982                            1/1     Running   0          24m
#kube-system   calico-kube-controllers-5b6544ffcd-v8xzp     1/1     Running   0          24m
#kube-system   metrics-server-85df567dd8-7nxwt              1/1     Running   0          20m
#kube-system   dashboard-metrics-scraper-58d4977855-xcxbh   1/1     Running   0          18m
#ingress       nginx-ingress-microk8s-controller-fqxc8      1/1     Running   0          18m
#kube-system   coredns-7f9c69c78c-klb24                     1/1     Running   0          18m
#kube-system   kubernetes-dashboard-59699458b-b6mv4         1/1     Running   0          18m

microk8s kubectl top nodes

#NAME          CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
#microk8s-vm   334m         16%    1592Mi          41%

#Al estar utilizando microk8s en un pc local solo vamos a tener disponible un nodo, que será el master. En un entorno real con alta disponibilidad lo ideal sería contar con 3 nodos master y 3 nodos workers en distintas zonas.
#Con microk8s podríamos añadir un nodo en otra VM o en otra máquina de la misma red para ello ejecutaríamos lo siguiente en el nodo master:

microk8s add-node

#Esto nos daría el comando necesario para conectar desde el nodo worker con este.

microk8s join 192.168.64.3:25000/896e4b78c7ec363cfd19d0ba2951bd31/fe1a780a3be9

# Continuamos siguiendo el walktrough e instalamos un pod de nginx en el namespace default:

microk8s kubectl run nginx --image nginx

microk8s kubectl  get pods
#NAME    READY   STATUS    RESTARTS   AGE
#nginx   1/1     Running   0          118s

# Para acceder al dashboard de microk8s, al instalarlo como addons de microk8s debemos hacerlo así:

microk8s dashboard-proxy

#Accedemos al dashboard con la url y el token facilitado. Se adjunta captura de la misma.

#microk8s_dashboard_nodes --> Muestra la información y el estado del nodo
#microk8s_dashboard_pods --> Muestra la información y el estado de los pods que se están ejecutando en el cluster
