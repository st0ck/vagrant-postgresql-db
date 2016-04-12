#!/bin/bash

PG_HOST_PORT=54321

APP_DB_USER=vagrant_db
APP_DB_PASS=

PG_DB_DUMP_PATH=/vagrant/db.dump

APP_DB_NAME=vagrant_db

PG_VERSION=9.4

#-------------------------------------------------------------------------------

add_repos () {
  PG_REPO_APT_SOURCE=/etc/apt/sources.list.d/pgdg.list
  if [ ! -f "$PG_REPO_APT_SOURCE" ]
  then
    # Add PG apt repo:
    echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" > "$PG_REPO_APT_SOURCE"

    # Add PGDG repo key:
    wget --quiet -O - https://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | apt-key add -
  fi
}

install_packages () {
  apt-get update
  apt-get -y upgrade
  apt-get -y install "postgresql-$PG_VERSION" "postgresql-contrib-$PG_VERSION"
}

configure_locales () {
  grep -q -F 'export LANGUAGE=en_US.UTF-8' /etc/bash.bashrc || echo 'export LANGUAGE=en_US.UTF-8' >> /etc/bash.bashrc
  grep -q -F 'export LANG=en_US.UTF-8' /etc/bash.bashrc || echo 'export LANG=en_US.UTF-8' >> /etc/bash.bashrc
  grep -q -F 'export LC_ALL=en_US.UTF-8' /etc/bash.bashrc || echo 'export LC_ALL=en_US.UTF-8' >> /etc/bash.bashrc
  sudo locale-gen en_US.UTF-8
  sudo dpkg-reconfigure locales
}

configure_postgesql () {
  PG_CONF="/etc/postgresql/$PG_VERSION/main/postgresql.conf"
  PG_HBA="/etc/postgresql/$PG_VERSION/main/pg_hba.conf"

  # Edit postgresql.conf to change listen address to '*':
  sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "$PG_CONF"

  # Append to pg_hba.conf to add password auth:
  PG_HBA_RULE="host    all             all             all                     md5"
  grep -q -F "$PG_HBA_RULE" "$PG_HBA" || echo "$PG_HBA_RULE" >> "$PG_HBA"

  # Explicitly set default client_encoding
  PG_CONF_ENCODING="client_encoding = utf8"
  grep -q -F "$PG_CONF_ENCODING" "$PG_CONF" || echo "$PG_CONF_ENCODING" >> "$PG_CONF"

  # Restart to load new configs:
  service postgresql restart

  # TODO: Add check if user and DB created
  echo "CREATE USER $APP_DB_USER WITH SUPERUSER PASSWORD '$APP_DB_PASS';" | su - postgres -c psql
  # echo "ALTER USER $APP_DB_USER WITH SUPERUSER;" | su - postgres -c psql
  echo "CREATE DATABASE $APP_DB_NAME WITH OWNER=$APP_DB_USER;" | su - postgres -c psql
}

restore_dump () {
  # echo "$APP_DB_PASS" | pg_restore -U "$APP_DB_USER" -O -h localhost -d "$APP_DB_NAME" "$PG_DB_DUMP_PATH"
  su - postgres -c "pg_restore -O -d $APP_DB_NAME $PG_DB_DUMP_PATH"
}

print_db_usage () {
  echo ""
  echo "Your PostgreSQL database has been setup and can be accessed on your local machine on the forwarded port (default: $PG_HOST_PORT)"
  echo "  Host: localhost"
  echo "  Port: $PG_HOST_PORT"
  echo "  Database: $APP_DB_NAME"
  echo "  Username: $APP_DB_USER"
  echo "  Password: $APP_DB_PASS"
  echo ""
  echo "Admin access to postgres user via VM:"
  echo "  vagrant ssh"
  echo "  sudo su - postgres"
  echo ""
  echo "psql access to app database user via VM:"
  echo "  vagrant ssh"
  echo "  sudo su - postgres"
  echo "  PGUSER=$APP_DB_USER PGPASSWORD=$APP_DB_PASS psql -h localhost $APP_DB_NAME"
  echo ""
  echo "Env variable for application development:"
  echo "  DATABASE_URL=postgresql://$APP_DB_USER:$APP_DB_PASS@localhost:$PG_HOST_PORT/$APP_DB_NAME"
  echo ""
  echo "Local command to access the database via psql:"
  echo "  PGUSER=$APP_DB_USER PGPASSWORD=$APP_DB_PASS psql -h localhost -p $PG_HOST_PORT $APP_DB_NAME"
}

add_repos
install_packages
configure_locales
configure_postgesql
restore_dump
print_db_usage
