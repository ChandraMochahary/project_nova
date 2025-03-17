    #!/bin/bash

    # Update package lists
    sudo apt update -y

    # Install PostgreSQL
    sudo apt install postgresql-contrib -y

    # Optionally, secure PostgreSQL (replace 'your_strong_password')
    sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD ${db_password};"

    # Optionally, create a database and user
    sudo -u postgres psql -c "CREATE DATABASE ${database_name};"
    sudo -u postgres psql -d ${database_name} -c "CREATE TABLE IF NOT EXISTS ${table_name} ( TX_ID VARCHAR(40) PRIMARY KEY, TX_TS TIMESTAMP, CUSTOMER_ID VARCHAR(30), TERMINAL_ID VARCHAR(20), TX_AMOUNT NUMERIC );" 

    sudo -u postgres psql -c "CREATE USER db_user WITH PASSWORD '${db_password}';"
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${database_name} TO ${db_username};"
    sudo -u postgres psql -d ${database_name} -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${db_username};"

    # Optionally, allow remote connections (modify pg_hba.conf carefully)
    sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/$(pg_lsclusters -h --no-header | awk '{print $1}')/main/postgresql.conf
    sudo sed -i '$ a host all all 0.0.0.0/0 md5' /etc/postgresql/$(pg_lsclusters -h --no-header | awk '{print $1}')/main/pg_hba.conf
    sudo systemctl restart postgresql

    sudo su postgres

    bq extract --destination_format CSV 'cymbal-fraudfinder:tx.tx' "gs://${bucket_name}/data/tx*.csv"
    gsutil -m cp "gs://${bucket_name}/data/tx0000000000*.csv" .

    sudo su 

    for file in tx*.csv; do
      sudo -u postgres psql -d ${database_name} -c "\copy ${table_name} FROM '$file' WITH (FORMAT CSV, HEADER, DELIMITER ',');"
    done

    echo "PostgreSQL installation complete."
