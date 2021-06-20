# HHEvaluation

## Local Setup

### Install the project

```sh
git clone git@github.com:azjezz/HHEvaluation.git hh-evaluation
cd hh-evaluation
composer install
```

### Start the database container

```sh
docker-compose up -d
```

### Run migrations

```sh
hhvm bin/console database:migrate
```

### Pull container images

```sh
hhvm bin/console container:pull
```

### Start the web server

```sh
hhvm -m server -c server.ini -p 8080
```
