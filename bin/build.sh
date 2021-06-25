APP_MODE=prod
composer install --no-dev
composer dump-autoload

hhvm bin/console.hack database:migrate

killall hhvm

rm -rf vendor/composer/* vendor/bin/* build/*
rm -f vendor/autoload.php

rm .gitattributes .gitignore composer.json composer.lock hh_autoload.json hhast-lint.json README.md
hhvm --hphp -t hhbc --input-dir . -o build

echo "hhvm.repo.authoritative = true" >> server.ini
echo "hhvm.repo.central.path = \""$(pwd)"/build/hhvm.hhbc\"" >> server.ini

hhvm -m daemon -c server.ini -p 8080

ab -c 100 -n 100000 http://localhost:8080/
