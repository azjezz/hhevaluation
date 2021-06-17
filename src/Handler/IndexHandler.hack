namespace HHEvaluation\Handler;

use namespace Nuxed\Http\{Handler, Message};

final class IndexHandler implements Handler\IHandler {
  /**
   * Handle the request and return a response.
   */
  public async function handle(
    Message\IServerRequest $_request,
  ): Awaitable<Message\IResponse> {
    return Message\Response\html_file(__DIR__.'/../../templates/index.html');
  }
}
