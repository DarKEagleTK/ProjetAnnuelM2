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