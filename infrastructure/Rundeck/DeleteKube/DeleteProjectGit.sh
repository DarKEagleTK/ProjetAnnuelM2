#!/bin/bash

# Variables
RD_OPTION_GITLAB_HOST="http://172.16.42.27:8080"
RD_OPTION_PRIVATE_TOKEN="glpat-Mw_-GubZVL3ozRZXbzxA"
RD_OPTION_APP="nginx"

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
