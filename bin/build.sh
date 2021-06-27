composer install --no-dev
composer dump-autoload

hhvm bin/console.hack build --production

killall hhvm

docker-compose up -d
hhvm -m daemon -c server.ini -p 8080

sleep 2

ab -c 100 -n 10000 http://localhost:8080/
