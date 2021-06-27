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

### Build the project

```sh
hhvm bin/console build
```

> for production build, make sure to pass the `--production` flag.

### Start the web server

```sh
hhvm -m server -c server.ini -p 8080
```
