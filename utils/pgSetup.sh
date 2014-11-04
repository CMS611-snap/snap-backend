#!/bin/bash

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