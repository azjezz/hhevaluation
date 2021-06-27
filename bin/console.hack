namespace HHEvaluation;

use namespace Nuxed\{Environment, Console};
use namespace Facebook\AutoloadMap;

<<__EntryPoint>>
async function console(): Awaitable<void> {
  require_once __DIR__.'/../vendor/autoload.hack';
  AutoloadMap\initialize();

  Environment\add('APP_MODE', 'dev');

  $application = new Console\Application();

  $application
    ->add(new Command\BuildCommand())
    ->add(new Command\NightlyCommand());

  await $application->run();
}
