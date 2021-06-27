composer install --no-dev

hhvm vendor/bin/hh-autoload --no-dev

docker-compose up -d

hhvm bin/console.hack build --production

kill -9 $(pidof hhvm) $(pidof hh_client) $(pidof hh_server)

hhvm -m daemon -c server.ini -p 8080

sleep 2

ab -c 100 -n 10000 http://localhost:8080/
