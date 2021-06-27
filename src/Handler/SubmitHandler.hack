namespace HHEvaluation\Handler;

use namespace HHEvaluation;
use namespace HHEvaluation\Model;
use namespace Nuxed\Http\{Handler, Message};
use namespace Facebook\TypeSpec;

final class SubmitHandler implements Handler\IHandler {
  public async function handle(
    Message\IServerRequest $request,
  ): Awaitable<Message\IResponse> {
    $structure = TypeSpec\of<Model\CodeSample::Structure>()
      ->assertType($request->getParsedBody());

    $pre_existing_code_sample = await Model\CodeSample::findDuplicate(
      $structure,
    );
    if ($pre_existing_code_sample is nonnull) {
      // avoid recreating/executing the same code twice.
      $code_sample = $pre_existing_code_sample;
    } else {
      $code_sample = await Model\CodeSample::create($structure);
    }

    return Message\Response\redirect(
      Message\uri('/c/'.$code_sample->getIdentifier()),
    );
  }
}
