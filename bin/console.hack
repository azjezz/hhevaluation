namespace HHEvaluation;

use namespace Nuxed\{Environment, Console};
use namespace Facebook\AutoloadMap;

<<__EntryPoint>>
async function console(): Awaitable<void> {
  require_once __DIR__.'/../vendor/autoload.hack';
  AutoloadMap\initialize();

  Environment\add('APP_MODE', 'dev');

  $application = new Console\Application('HHEvaluation');

  $application
    ->add(new Command\Database\MigrateCommand())
    ->add(new Command\Container\PullCommand());

  await $application->run();
}
