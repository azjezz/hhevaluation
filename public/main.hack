namespace HHEvaluation;

use namespace Nuxed\{Cache, Environment, EventDispatcher, Http};
use namespace Facebook\AutoloadMap;

<<__EntryPoint>>
async function main(): Awaitable<void> {
  Environment\add('APP_MODE', 'dev');

  $listeners =
    new EventDispatcher\ListenerProvider\AttachableListenerProvider();
  $listeners->listen<Http\Event\BeforeEmitEvent>(
    EventDispatcher\EventListener\callable<Http\Event\BeforeEmitEvent>(async (
      $event,
    ) ==> {
      $response = $event->getResponse()
        |> $$->withHeader('X-Powered-By', vec['Nuxed']);

      if (Environment\mode() === Environment\Mode::PRODUCTION) {
        $response = $response
          ->withHeader('Strict-Transport-Security', vec['max-age=31536000'])
          ->withHeader(
            'Content-Security-Policy',
            vec['upgrade-insecure-requests'],
          );
      }

      $event->setResponse($response);

      return $event;
    }),
  );

  $cache = new Cache\Cache(new Cache\Store\ApcStore());
  $application = new Http\Application(vec[], $cache, null, null, $listeners);

  $application
    ->get('index', '/', new Handler\IndexHandler())
    ->post('code-sample:create', '/c', new Handler\CodeSample\CreateHandler())
    ->get('code-sample:show', '/c/{id}', new Handler\CodeSample\ShowHandler())
    ->get(
      'type-checker:result',
      '/t/{id}/{version}',
      new Handler\TypeChecker\ResultHandler(),
    )
    ->get(
      'runtime:result',
      '/r/{id}/{version}',
      new Handler\Runtime\ResultHandler(),
    );
  ;

  await $application->run();
}
