namespace HHEvaluation\EventListener;

use namespace Nuxed\Environment;
use namespace Nuxed\EventDispatcher\EventListener;
use namespace Nuxed\Http\Event;

final class SecurityHeadersEventListener
  implements EventListener\IEventListener<Event\BeforeEmitEvent> {

  /**
   * Process the given event, and return it.
   */
  public async function process(
    Event\BeforeEmitEvent $event,
  ): Awaitable<Event\BeforeEmitEvent> {
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
  }
}
