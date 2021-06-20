namespace HHEvaluation\Handler\CodeSample;

use namespace HHEvaluation;
use namespace HHEvaluation\Model;
use namespace Nuxed\Http\{Handler, Message};
use namespace Facebook\TypeSpec;

final class CreateHandler implements Handler\IHandler {
  public async function handle(
    Message\IServerRequest $request,
  ): Awaitable<Message\IResponse> {
    $structure = TypeSpec\of<Model\CodeSample::Structure>()
      ->assertType($request->getParsedBody());

    $code_sample = await Model\CodeSample::create($structure);

    return Message\Response\redirect(
      Message\uri('/c/'.$code_sample->getIdentifier()),
    );
  }
}
