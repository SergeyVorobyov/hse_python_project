mkdir -p ./airflow/logs ./airflow/plugins ./airflow/config ./mysql/mysql_data ./postgres/pgdata
echo -e "AIRFLOW_UID=$(id -u)" > .env
