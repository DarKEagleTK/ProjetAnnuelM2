#!/bin/bash

# Variables
GITLAB_HOST="http://172.16.42.27:8080"
PRIVATE_TOKEN="glpat-Mw_-GubZVL3ozRZXbzxA"
SEARCH_TERM="nginx"

# Effectuer la recherche et extraire l'ID du premier projet trouvé
response=$(curl --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" "$GITLAB_HOST/api/v4/projects?search=$SEARCH_TERM")

# Extraire l'ID du projet en utilisant awk (supposant que le format JSON est simple)
project_id=$(echo "$response" | grep -o '"id":[0-9]*' | awk -F: '{print $2}' | head -n 1)

# Vérifier si l'ID du projet est vide
if [ -z "$project_id" ]; then
    echo "Aucun projet trouvé avec le terme de recherche '$SEARCH_TERM'."
    exit 1
fi

echo "ID du projet trouvé avec '$SEARCH_TERM' : $project_id"

# Supprimer le projet
delete_response=$(curl --request DELETE --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" "$GITLAB_HOST/api/v4/projects/$project_id")

# Vérifier si la suppression a réussi
if [ $? -eq 0 ]; then
    echo "Projet avec ID $project_id supprimé avec succès."
else
    echo "Erreur lors de la suppression du projet avec ID $project_id."
    echo "$delete_response"
    exit 1
fi
