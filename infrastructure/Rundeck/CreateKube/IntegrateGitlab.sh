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