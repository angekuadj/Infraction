#!/bin/bash

# Charger les variables d'environnement depuis .env
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
    echo "Variables d'environnement chargées depuis .env"
else
    echo "Fichier .env non trouvé, utilisation des valeurs par défaut"
fi

# Démarrer l'application Spring Boot
mvn spring-boot:run
