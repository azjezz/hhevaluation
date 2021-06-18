# HHEvaluation

## Local Setup

### Install the project

```sh
git clone git@github.com:azjezz/HHEvaluation.git hhevaluation
cd hhevaluation
composer install
```

### Start the database container

```sh
docker-compose up -d
```

### Setup database, and pull docker images
```sh
hhvm bin/console hhevaluation:setup
```

### Start the web server

```sh
hhvm -m server -c server.ini -p 8080
```
