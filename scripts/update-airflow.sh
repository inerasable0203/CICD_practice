#!/usr/bin/env bash
set -euo pipefail

compose_file="$(dirname "$0")/../compose.yaml"
image=ghcr.io/inerasable0203/cicd_practice:latest
docker compose -f "$compose_file" pull -q airflow

# The old image keeps DAGs inside AIRFLOW_HOME. Wait for the new layout before mounting it.
if [[ $(docker image inspect -f '{{ index .Config.Labels "io.cicd-practice.persistent-dags" }}' "$image") != true ]]; then
  exit 0
fi

if docker container inspect airflow-practice >/dev/null 2>&1 &&
   [[ $(docker inspect -f '{{ index .Config.Labels "com.docker.compose.project" }}' airflow-practice) != cicd-practice ]]; then
  backup_name=airflow-practice-before-compose
  if docker container inspect "$backup_name" >/dev/null 2>&1; then
    echo "Backup container $backup_name already exists" >&2
    exit 1
  fi

  backup_dir=$(mktemp -d)
  migrating=1
  cleanup() {
    if [[ $migrating == 1 ]]; then
      docker compose -f "$compose_file" down >/dev/null 2>&1 || true
      if docker container inspect "$backup_name" >/dev/null 2>&1; then
        docker rename "$backup_name" airflow-practice
      fi
      docker start airflow-practice >/dev/null || true
    fi
    rm -rf "$backup_dir"
  }
  trap cleanup EXIT

  docker stop airflow-practice
  docker cp airflow-practice:/opt/airflow/. "$backup_dir/"
  docker volume create cicd-practice-airflow-data >/dev/null
  docker run --rm --user 0 --entrypoint /bin/bash \
    -v "$backup_dir:/source:ro" \
    -v cicd-practice-airflow-data:/target \
    "$image" -c 'cp -a /source/. /target/ && chown -R 50000:0 /target'
  docker rename airflow-practice "$backup_name"
  docker compose -f "$compose_file" up -d --wait --wait-timeout 180 airflow
  migrating=0
else
  docker compose -f "$compose_file" up -d --wait --wait-timeout 180 airflow
fi
