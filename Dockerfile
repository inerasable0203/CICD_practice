FROM apache/airflow:3.3.2

LABEL org.opencontainers.image.source="https://github.com/inerasable0203/CICD_practice"

ENV AIRFLOW__CORE__LOAD_EXAMPLES=False
ENV AIRFLOW__CORE__PARALLELISM=2

COPY --chown=airflow:root dags/ /opt/airflow/dags/
