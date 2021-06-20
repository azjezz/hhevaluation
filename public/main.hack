namespace HHEvaluation;

use namespace Nuxed\{Cache, Environment, Http};
use namespace Facebook\AutoloadMap;

<<__EntryPoint>>
async function main(): Awaitable<void> {
  require_once __DIR__.'/../vendor/autoload.hack';
  AutoloadMap\initialize();

  Environment\add('APP_MODE', 'dev');

  $cache = new Cache\Cache(new Cache\Store\ApcStore());
  $application = new Http\Application(vec[], $cache);

  $application
    ->get('index', '/', new Handler\IndexHandler())
    ->post('code-sample:create', '/c', new Handler\CodeSample\CreateHandler())
    ->get('code-sample:show', '/c/{id}', new Handler\CodeSample\ShowHandler())
    ->get('type-checker:result', '/t/{id}/{version}', new Handler\TypeChecker\ResultHandler())
    ->get('runtime:result', '/r/{id}/{version}', new Handler\Runtime\ResultHandler());
  ;

  await $application->run();
}
