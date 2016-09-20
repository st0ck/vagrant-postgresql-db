#!/bin/bash

PG_HOST_PORT=54321

# TODO: Make it work with non-empty password
APP_DB_PASS=
APP_DB_USER=vagrant_db

PG_DB_DUMP_PATH=/vagrant/db.dump

APP_DB_NAME=vagrant_db

PG_VERSION=9.5

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
  apt-get -y install "postgresql-$PG_VERSION" \
                     "postgresql-contrib-$PG_VERSION" \
                     "postgresql-server-dev-$PG_VERSION" \
                     "git"
}

configure_locales () {
  rm /etc/bash.bashrc
  ln -s /vagrant/configs/bash.bashrc /etc/bash.bashrc
  chown -h vagrant:vagrant /etc/bash.bashrc
  locale-gen en_US.UTF-8
  dpkg-reconfigure locales
}

configure_postgesql () {
  PG_CONF="/etc/postgresql/$PG_VERSION/main/postgresql.conf"
  PG_HBA="/etc/postgresql/$PG_VERSION/main/pg_hba.conf"

  # Create symlinks to PG configs
  rm "$PG_CONF"
  rm "$PG_HBA"
  ln -s /vagrant/configs/postgresql.conf "$PG_CONF"
  ln -s /vagrant/configs/pg_hba.conf "$PG_HBA"
  chown -h postgres:postgres "$PG_CONF"
  chown -h postgres:postgres "$PG_HBA"

  # Restart to load new configs:
  su - postgres service postgresql restart

  # TODO: Add check if user and DB created
  echo "CREATE USER $APP_DB_USER WITH SUPERUSER PASSWORD '$APP_DB_PASS';" | su - postgres -c psql
  # echo "ALTER USER $APP_DB_USER WITH SUPERUSER;" | su - postgres -c psql
  echo "CREATE DATABASE $APP_DB_NAME WITH OWNER=$APP_DB_USER;" | su - postgres -c psql
  echo "CREATE DATABASE ${APP_DB_NAME}_test WITH OWNER=$APP_DB_USER;" | su - postgres -c psql

  install_temporal_tables
}

install_temporal_tables () {
  git clone https://github.com/arkhipov/temporal_tables
  cd temporal_tables
  make
  make install PGUSER=postgres
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
