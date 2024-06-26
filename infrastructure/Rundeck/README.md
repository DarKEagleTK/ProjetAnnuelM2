# Rundeck

Sur la partie Rundeck, 2 traitements seront a crée :

*La création d'un déploiement d'applications web en 2 parties:*
- Création d'un déploiement Kubernetes avec namespace dédié
- Création d'un projet dans GitLab

*La suppresion d'un déploiement d'applications web*
- Purge complète des ressources créer dans Kubernetes
- Suppression du projet dans Gitlab

Chaque traitement auront été écrit sur du bash, avec des fichiers yaml

Voici un schéma simple afin de visualiser la communication entre chacune des technologies :
![](../src/schemasimple.png)

# Procédure de création projet

Afin de prendre en compte la diversité des applications web, j'ai dynamisé le traitement Rundeck avec des options:
![](../src/optioncreate.png)

Et nous commençons par créer un namespace dédié à l'application que nous souhaitons créer:

```bash
kubectl --kubeconfig /home/user/.kube/config create namespace "${option.APP}-namespace"
```

L'étape suivante dans le workflow est la création du configmap.yml, service.yml et déployment.yml.

### Configmap.yml

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${option.APP}-website
data:
  index.html: |
    <html>
    <h1>Les grandes perches (et la oompa loompa)</h1>
    <body>
    Vous ne croirez jamais ce que se cache derriere ce lien ! Decouvrez le contenu le plus etonnant de tous les temps ! <br />
    <a href="https://www.youtube.com/watch?v=dQw4w9WgXcQ">Cliquez ici !</a>
    </body>
    </html>
```

### Service.yml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: ${option.APP}-service-lb
spec:
  type: LoadBalancer
  loadBalancerIP: 10.1.0.51  # Adresse IP statique souhaitée
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  selector:
    app: ${option.APP}
```

### Deployment.yml

```yaml
${option.APP}apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${option.APP}-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${option.APP}
  template:
    metadata:
      labels:
        app: ${option.APP}
    spec:
      containers:
        - name: ${option.APP}
          image: ${option.APP}
          ports:
            - containerPort: 80
          volumeMounts:
            - name: ${option.APP}-website-volume
              mountPath: /usr/share/${option.APP}/html
              readOnly: true
      volumes:
        - name: ${option.APP}-website-volume
          configMap:
            name: ${option.APP}-website
```

Grâce à un plugin, nous avons ces étapes spécifiques à kubernetes, qui applique automatiquement les fichiers crée.

![alt text](../src/createkube.png)

Une fois le déploiement effectué, nous devons crée un projet et je rajoute le configmap dans le repository.


```bash
#!/bin/bash

# Variables en dur
RD_OPTION_APP="nginx"
RD_OPTION_GITLAB_NAME="Rundeck"
RD_OPTION_GITLAB_HOST="172.16.42.27"
RD_OPTION_USER_MAIL="rundeck@myges.fr"
RD_OPTION_GITLAB_TOKEN="glpat-Mw_-GubZVL3ozRZXbzxA"
RD_OPTION_SSH_KEY_PATH="~/.ssh/id_rsa"  # Chemin de la clé SSH

# Démarrer l'agent SSH
eval $(ssh-agent)

# Ajouter la clé SSH à l'agent
ssh-add ${RD_OPTION_SSH_KEY_PATH}

# Créer un nouveau dossier pour l'application
mkdir -p "${RD_OPTION_APP}-folder"
cd "${RD_OPTION_APP}-folder"

# Initialiser un dépôt Git
git init

# Configurer les informations utilisateur Git
git config --global user.name "${RD_OPTION_GITLAB_NAME}"
git config --global user.email "${RD_OPTION_USER_MAIL}"

# Désactiver la vérification SSL
git config http.sslVerify "false"

# Ajouter la clé hôte de GitLab au fichier known_hosts
ssh-keyscan -H ${RD_OPTION_GITLAB_HOST} >> ~/.ssh/known_hosts

# Créer le projet sur GitLab avec curl
curl --request POST --header "PRIVATE-TOKEN: ${RD_OPTION_GITLAB_TOKEN}" --data "name=${RD_OPTION_APP}-project" "http://${RD_OPTION_GITLAB_HOST}:8080/api/v4/projects"

# Supprimer l'origine existante et ajouter une nouvelle origine avec le token d'accès
git remote remove origin
git remote add origin git@${RD_OPTION_GITLAB_HOST}:${RD_OPTION_GITLAB_NAME}/${RD_OPTION_APP}-project.git

# Vérifier le remote
git remote -v

# Récupérer le ConfigMap de Kubernetes et le sauvegarder dans configmap.yaml
kubectl --kubeconfig /home/user/.kube/config get configmap ${RD_OPTION_APP}-conf -o yaml > configmap.yaml

# Ajouter les modifications et faire un commit initial
git add .
git commit -m "Initial commit and files added"

# Pousser les modifications vers GitLab
git push -u origin master
```

Et enfin nous rajoutons un script qui permettra de créer un fichier gitlab-ic.yml et de l'intégrer dans le gitlab.

```bash
#!/bin/bash

# Définir le nom du fichier
FILE_NAME=".gitlab-ci.yml"

# Définir le contenu YAML
cd "${RD_OPTION_APP}-folder"
cat <<EOL > $FILE_NAME
variables:
  KUBE_CONTEXT: elite/k8s-connection:k8s-connection

stages:
  - deploy

deploy-configmap:
  stage: deploy
  image:
    name: bitnami/kubectl:latest
    entrypoint: ['']
  script:
    - kubectl config use-context \$KUBE_CONTEXT
    - kubectl apply -f \$CI_PROJECT_DIR/configmap.yaml
EOL

echo "Le fichier $FILE_NAME a été créé avec succès."

# Ajouter les modifications et faire un commit initial
git add .
git commit -m "Add Gitlab-ci.yml"

# Pousser les modifications vers GitLab
git push -u origin master
```

# Procédure de suppression projet

![OptionDelete](../src/optiondelete.png)

Dans le cadre de la suppression de projet, j'ai crée 2 script :
1. Pour supprimer toutes les ressources dans le namespace de l'application demandée, ensuite le namespace en question.

```bash
#!/bin/bash

kubectl --kubeconfig /home/user/.kube/config delete all --all -n $RD_OPTION_APP-namespace
kubectl --kubeconfig /home/user/.kube/config delete namespace $RD_OPTION_APP-namespace
```
2. Pour chercher le projet portant le nom de l'application demandé dans GitLab pour le supprimer ensuite.

```bash
#!/bin/bash

# Effectuer la recherche et extraire l'ID du premier projet trouvé
response=$(curl --header "PRIVATE-TOKEN: $RD_OPTION_PRIVATE_TOKEN" "$RD_OPTION_GITLAB_HOST/api/v4/projects?search=$RD_OPTION_APP")

# Vérifier si la commande curl a réussi (code HTTP 200)
if [ $? -ne 0 ]; then
    echo "Erreur lors de l'exécution de la commande curl."
    exit 1
fi

# Extraire l'ID du premier projet correspondant
project_id=$(echo "$response" | jq '.[0].id')

# Vérifier si l'ID du projet est vide
if [ -z "$project_id" ] || [ "$project_id" == "null" ]; then
    echo "Aucun projet trouvé avec le terme de recherche '$RD_OPTION_APP'."
    exit 1
fi

echo "ID du projet trouvé avec '$RD_OPTION_APP' : $project_id"

# Supprimer le projet
delete_response=$(curl --request DELETE --header "PRIVATE-TOKEN: $RD_OPTION_PRIVATE_TOKEN" "$RD_OPTION_GITLAB_HOST/api/v4/projects/$project_id")

# Vérifier si la suppression a réussi
if [ $? -eq 0 ]; then
    echo "Projet avec ID $project_id supprimé avec succès."
else
    echo "Erreur lors de la suppression du projet avec ID $project_id."
    echo "$delete_response"
    exit 1
fi

rm -r RD_OPTION_APP-folder
```