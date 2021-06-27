namespace HHEvaluation;

use namespace Nuxed\{Cache, Environment, Http};
use namespace Facebook\AutoloadMap;

<<__EntryPoint>>
async function main(): Awaitable<void> {
  require_once __DIR__.'/../vendor/autoload.hack';
  AutoloadMap\initialize();

  Environment\add('APP_MODE', 'dev');

  $cache = new Cache\Cache(new Cache\Store\ApcStore());
  $application = new Http\Application(null, vec[], null, $cache);

  $application->listen<Http\Event\BeforeEmitEvent>(
    new EventListener\SecurityHeadersEventListener(),
  );

  await $application

    ->get('/', new Handler\IndexHandler())
    ->get('/c/{id}', new Handler\ShowHandler())
    ->get('/c/{id}/result/{version}', new Handler\ResultHandler())

    ->post('/c', new Handler\SubmitHandler())

    ->run();
}
