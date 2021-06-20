namespace HHEvaluation\Handler\CodeSample;

use namespace HHEvaluation;
use namespace HHEvaluation\{Model, Template};
use namespace Nuxed\Http\{Exception, Handler, Message};

final class ShowHandler implements Handler\IHandler {
  public async function handle(
    Message\IServerRequest $request,
  ): Awaitable<Message\IResponse> {
    $identifier = (int)$request->getAttribute<string>('id');
    $code_sample = await Model\CodeSample::findOne($identifier);
    if (null === $code_sample) {
      throw new Exception\NotFoundException();
    }

    $query = $request->getQueryParams();
    $selected_version = $query['version'] ?? null;

    return Message\Response\html(
      await Template\CodeSample\ShowTemplate::render($code_sample, $selected_version),
    );
  }
}
