
namespace HHEvaluation\Handler;

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

    return Message\Response\html($content);
  }
}
