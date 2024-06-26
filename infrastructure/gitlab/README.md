# Kubernetes gitlab ci/cd

## Etape 1 : Ajouter un repo de connexion vers kubernetes

- creer le repo k8s-connection
- créer un fichier .gitlab/agents/k8s-connection/config.yaml
    - Ce fichier sert comme un firewall. Il faut ajouter les repos qui peuvent se connecter dessus.
- Aller dans l'onglet operate>kubernetes clusters
- cliquer sur connect a cluster, puis selectionner l'agent k8s-cluster
- Utiliser la commande sur le master kubernetes pour permettre la connection au gitlab

.gitlab/agents/k8s-connection/config.yaml : 
```yaml
ci-access:
  groups:
    - id: Rundeck/nginx-project # path to repo authorized
```

```bash
helm upgrade --install k8s-connection gitlab/gitlab-agent \
    --namespace gitlab-agent-k8s-connection \
    --create-namespace \
    --set image.tag=v17.1.0 \
    --set config.token=<token> \
    --set config.kasAddress=ws://172.16.42.27:8080/-/kubernetes-agent/
    --set replicas=1
```

## Etape 2 : Ci/Cd

- créer un fichier .gitlab-ci.yaml

```yaml
variables:
  KUBE_CONTEXT: elite/k8s-connection:k8s-connection # utiliser la connexion kubernetes monter plus tot

stages:
  - deploy # on ne fait que tu deploiment.

deploy-configmap: # notre job
  stage: deploy # job de type deploiment
  image:
    name: bitnami/kubectl:latest # on utilise kubectl
    entrypoint: ['']
  script:
    - kubectl config use-context $KUBE_CONTEXT # On utilise la connexion avec kubernetes monté plus tot pour lancer des commandes kubectl
    - kubectl apply -f $CI_PROJECT-DIR/configmap.yaml # On utilise le fichier configmap modifier pour le mettre a jour sur le kubernetes
```