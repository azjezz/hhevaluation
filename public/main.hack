namespace HHEvaluation;

use namespace Nuxed\{Cache, Environment, EventDispatcher, Http};
use namespace Facebook\AutoloadMap;

<<__EntryPoint>>
async function main(): Awaitable<void> {
  require_once __DIR__.'/../vendor/autoload.hack';
  AutoloadMap\initialize();

  Environment\add('APP_MODE', 'dev');

  $listeners =
    new EventDispatcher\ListenerProvider\AttachableListenerProvider();

  $listeners->listen<Http\Event\BeforeEmitEvent>(
    new EventListener\SecurityHeadersEventListener(),
  );

  $cache = new Cache\Cache(new Cache\Store\ApcStore());
  $application = new Http\Application(vec[], $cache, null, null, $listeners);

  $application
    ->get('index', '/', new Handler\IndexHandler())
    ->post('code-sample:create', '/c', new Handler\CodeSample\CreateHandler())
    ->get('code-sample:show', '/c/{id}', new Handler\CodeSample\ShowHandler())
    ->get(
      'type-checker:result',
      '/type-checker/result/{id}/{version}',
      new Handler\TypeChecker\ResultHandler(),
    )
    ->get(
      'runtime:result',
      '/runtime/result/{id}/{version}',
      new Handler\Runtime\ResultHandler(),
    );

  await $application->run();
}
