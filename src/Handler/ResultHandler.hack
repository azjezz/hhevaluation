
namespace HHEvaluation\Handler;

use namespace HHEvaluation\{Service, Template};
use namespace Nuxed\Http\{Handler, Message};

final class ResultHandler implements Handler\IHandler {
  public async function handle(
    Message\IServerRequest $request,
  ): Awaitable<Message\IResponse> {
    $identifier = $request->getAttribute<string>('identifier');

    $db = await Service\Database::get();
    $result = await $db->findEvaluation($identifier);
    if (null === $result) {
      // TODO(azjezz): create a template for this?
      return Message\Response\empty(Message\StatusCode::NOT_FOUND);
    }

    $template = await Template\ResultTemplate::render($result);

    return Message\Response\html($template);
  }
}