#Practica 5. Unidad 6. Multicontainer Pods

Creamos un deployment con 3 contenedores:

- backend: Es el mismo de la unidad anterior
- frontend: Es el nuevo contenedor con la imagen del frontend
- initcontainer: para la migración inicial de la db y que usa la imagen del backend

Creamos de forma imperativa un nuevo namespace para la unidad:

```bash
uk create ns unit6
namespace/unit6 created
```
Utilizamos el mismo configmap de la practica anterior y lo desplegamos en el nuevo namespace.

Desplegamos el manifiesto creado y comprobamos que se despliegan todos los contenedores correctamente:

```bash
 uk get pods -n unit6 -w
NAME                               READY   STATUS    RESTARTS   AGE
k8s4arch-hotels-7f8c678986-crtvz   0/2     Pending   0          0s
k8s4arch-hotels-7f8c678986-crtvz   0/2     Pending   0          0s
k8s4arch-hotels-7f8c678986-crtvz   0/2     Init:0/1   0          0s
k8s4arch-hotels-7f8c678986-crtvz   0/2     Init:0/1   0          1s
k8s4arch-hotels-7f8c678986-crtvz   0/2     PodInitializing   0          3s
k8s4arch-hotels-7f8c678986-crtvz   0/2     Running           0          4s
k8s4arch-hotels-7f8c678986-crtvz   1/2     Running           0          15s
k8s4arch-hotels-7f8c678986-crtvz   2/2     Running           0          24s
```
Comprobamos que se han aplicado las nuevas labels configuradas:

```bash
 uk get pods -n unit6 --show-labels
NAME                              READY   STATUS    RESTARTS   AGE   LABELS
k8s4arch-hotels-9b784f48f-bdsh7   2/2     Running   0          80s   app=k8s4arch-hotels,pod-template-hash=9b784f48f,tier=backend-fronted,version=slim
```
Comprobamos que el initcontainer con el script de migración ha funcionado correctamente y la comunicación entre los contenedores de backend y frontend:

```bash
uk exec -ti deploy/k8s4arch-hotels -c k8s4arch-hotels-fronted -n unit6 -- curl http://localhost:5000/hotels
kubectl exec [POD] [COMMAND] is DEPRECATED and will be removed in a future version. Use kubectl exec [POD] -- [COMMAND] instead.
[{"availabilityFrom":1635095131437,"availabilityTo":1635959131437,"city":"Buenos Aires","country":"Argentina","description":"La Bamba de Areco est\u00e1 ubicada en San Antonio de Areco, en el coraz\u00f3n de la pampa. Es una de las estancias m\u00e1s antiguas de la Argentina, recientemente restaurada para ofrecer a sus hu\u00e9spedes todo el confort y esplendor colonial.","name":"La Bamba de Areco","photo":"/9j/4AAQSkZJRgABAQAASABIAAD/2wCEAAICAgICAgMCAgMEAwMDBAUEBAQEBQcFBQUFBQcIBwcHBwcHCAgICAgICAgKCgoKCgoLCwsLCw0NDQ0NDQ0NDQ0BAgICAwMDBgMDBg0JBwkNDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDf/CABEIAeACgAMBIgACEQEDEQH/xAAeAAACAgMBAQEBAAAAAAAAAAAGBwUIAwQJAgEKAP/aAAgBAQAAAADnuyRqSMZJhIVqmq6lke37tVp2qnnfo71mXLu4qsl5Vg8gGFP16T7sSDIFoZGNWOZSaB/RCNE+vuLKyirXlibp1NpnKlOMQwaG7pnz4Rq3HCGALbFuEET8RgkTWIh7gj9a2JjOa7v6w1DWAACTUY2ctcUTehkphJo9CW2tbSNdX0bGyr9GhywsafJBar2KwzdkhWoxO0a+P0UW0mM7gERDZmtS7T6L1pQ+lrZ2M2LvqMcqGOeDkxs6SyyQ1IS7lDTOzqgX4GA2QsiTQibb9s66FEEmZWzNUkizOhSuY3Nsbt3bKtcQoF3O1Yjno3UaABmmd6l5qDDGFfSmpu2rVyQwYp+z0BW6a9te4G+hxVcgU87WNoLy01S28ehhLYllCIpVOykm4durFrbuV2r5CdGEnzvqXqXFtpXVeAURYVxezFD1hKSZFOiGp2cXlpzWW2TFqZHsqs0Mxi93J5G6uApbZNqSEXYGFthSDeBFyWOPQAidkQo/dGnViWqcyGGpbkWrltGmbLuZBAFP7YB1PF65Wt7l/qgr5P3nXz7qzz7FrjJRa2JrDgZ6HKSfWSbCtIE0+tEHnJ3UjZklyYlBSyIKuJfeiihExyBV2WhZA2r8w2cSGZH8RDncY/AZxVvq2zIS01voi9Y03b/blmlWmDUajlc147iV1oQnIL7DH0TpMqvDUVAh9sq6Q2u6r13MuIKViMMsaWvSjcp4QQoO79ApICScL7K18azag5vfHqrPJ0R8xvh633OhcAslySaI2RqKDbdwKrUXWc8YWsJX8e8Icc/g8nCuXSimNkwzzjWWUkpF/q54+SySOaS8T7CQ3jXKg0vKPo3KtSyJ8EswIJJsZy4XYq9qaZWr4IJ8ZIFvlZ4hkWAg7kvUbS1HHYiuPTa83MbijYBGnofbZIiAKeBWefN/Q2tdHxqSvvTksopqsxXzc1s7czXu2Der4XqWUuOCvfYsilVE7THUKa/CDy051gh0pqi/oQLJaf1V0ua6ykFjNpC0/SHNzm5HNlWTurPedBfN75qaHuPERben2ip8G9vl8hFwipCNo6Ki5dX0Akzp6UkRveyTZU8jh1JkdFZ5NOwAn524aIJBYlK1gwl8Rh6EHY2yaoXTIL+gZjzeo2CDWjNts+AqnX/DkwwRZTwgyW5SkjRhX9LtS5iQ1x5Jf02OlXU1HVGgdI8OXUeN4RrQ5I9KCxG3h6XcTlEGopLoZdkQ+VzWVs/caj
```
Hacemos un port forwarding al puerto del contenedor fronted y comprobamos que carga correctamente:

```bash

uk port-forward k8s4arch-hotels-9b784f48f-bdsh7 -n unit6 8080:80
Forwarding from 127.0.0.1:8080 -> 80
Forwarding from [::1]:8080 -> 80
Handling connection for 8080

```
Comprobamos que nos carga el frontal de la aplicación.

Para la comunicación entre el initContainer y el contenedor de backend es necesario configurar un volumen al pod con un emptyDir, este volumen es un volumen de espacio temporal para la comunicación entre los dos contenedores. También ha sido necesario configurar un punto de montaje en el volumen anterior para los dos contenedores. 

Para el contenedor de fronted se han configurado unos recursos similares a los del contenedor de backend y se han configurado las probes apuntando al puerto 80, con un delay inicial ligeramente superior al del backend.
