namespace HHEvaluation;

use namespace Nuxed\{Cache, Environment, Http};
use namespace Facebook\AutoloadMap;

<<__EntryPoint>>
async function main(): Awaitable<void> {
  require_once __DIR__.'/../vendor/autoload.hack';
  AutoloadMap\initialize();

  Environment\add('APP_MODE', 'dev');

  $runner = new Runner\Runner(\sys_get_temp_dir() as string);

  $cache = new Cache\Cache(new Cache\Store\ApcStore());
  $application = new Http\Application(vec[], $cache);

  $application
    ->get('index', '/', new Handler\IndexHandler())
    ->post('execute', '/execute', new Handler\ExecuteHandler($runner));

  await $application->run();
}
