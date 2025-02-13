#!/bin/sh
sudo docker compose pull
sudo docker compose build
sudo docker compose run inferno bundle exec inferno migrate
