#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

$DIR/pgStop.sh &>/dev/null

sleep 0.5

if [ -d "/usr/local/var/postgres" ]; then
  read -p "A postgres environment is already set up on this machine. Are you sure you want to reset it? (y/n) " -n 1 -r
  echo    # (optional) move to a new line
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    rm -R /usr/local/var/postgres
  else
    exit 1
  fi
fi

initdb /usr/local/var/postgres -E utf8

$DIR/pgStart.sh >/dev/null

sleep 0.5

createdb
createdb snap

createuser -s snap

hash knex &> /dev/null
if [ $? -eq 1 ]; then
    echo >&2 "knex execuble not found. The server has been set up and started, but you need to install knex and run the migrations manually."
    exit 1;
fi

knex migrate:latest

echo "Setup complete. The server has been started automatically, you don't need to start it again."