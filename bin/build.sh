composer install --no-dev
composer dump-autoload

docker-compose up -d

hhvm bin/console.hack build --production

killall hhvm

hhvm -m daemon -c server.ini -p 8080

sleep 2

ab -c 100 -n 10000 http://localhost:8080/
