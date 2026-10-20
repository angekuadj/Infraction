#!/bin/bash
# Lance le backend Circulation sur PostgreSQL local.
set -e
cd "$(dirname "$0")"

export SPRING_DATASOURCE_URL="${SPRING_DATASOURCE_URL:-jdbc:postgresql://localhost:5432/circulation}"
export SPRING_DATASOURCE_USERNAME="${SPRING_DATASOURCE_USERNAME:-circulation}"
export SPRING_DATASOURCE_PASSWORD="${SPRING_DATASOURCE_PASSWORD:-circulation}"
export SPRING_DATASOURCE_DRIVER="${SPRING_DATASOURCE_DRIVER:-org.postgresql.Driver}"

exec mvn -o spring-boot:run
