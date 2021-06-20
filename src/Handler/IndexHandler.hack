
namespace HHEvaluation\Handler;

use namespace HHEvaluation;
use namespace HHEvaluation\Template;
use namespace Nuxed\Http\{Handler, Message};

final class IndexHandler implements Handler\IHandler {
  /**
   * Handle the request and return a response.
   */
  public async function handle(
    Message\IServerRequest $_request,
  ): Awaitable<Message\IResponse> {
    $content = await Template\IndexTemplate::render();

    return Message\Response\html($content)
      |> Message\Response\with_cache_control_directive($$, 'must-revalidate')
      |> Message\Response\with_cache_control_directive($$, 'public')
      |> Message\Response\with_max_age($$, 86400)
      |> Message\Response\with_last_modified(
        $$,
        HHEvaluation\Utils::getCurrentDatetime()
          ->modify('-1 day')
          ->getTimestamp(),
      );
  }
}
