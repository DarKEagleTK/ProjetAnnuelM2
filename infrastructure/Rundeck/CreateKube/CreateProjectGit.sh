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
