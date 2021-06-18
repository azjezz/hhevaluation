namespace HHEvaluation;

use namespace Nuxed\{Cache, Environment, Http};
use namespace Facebook\AutoloadMap;

<<__EntryPoint>>
async function main(): Awaitable<void> {
  require_once __DIR__.'/../vendor/autoload.hack';
  AutoloadMap\initialize();

  Environment\add('APP_MODE', 'dev');

  $cache = new Cache\Cache(new Cache\Store\NullStore());
  $application = new Http\Application(vec[], $cache);

  $application
    ->get('index', '/', new Handler\IndexHandler())
    ->post('evaluate', '/e', new Handler\EvaluateHandler())
    ->get('result', '/r/{identifier}', new Handler\ResultHandler());

  await $application->run();
}
