
namespace HHEvaluation\Handler;

use namespace HHEvaluation;
use namespace HHEvaluation\HHVM;
use namespace HHEvaluation\Service;
use namespace Nuxed\Http\{Handler, Message};
use namespace HH\Lib\{File, Str};
use namespace Facebook\TypeSpec;

final class EvaluateHandler implements Handler\IHandler {
  const type Request = shape(
    'code' => string,
    'configuration' => string,
    'version' => HHVM\Version,
    ...
  );

  public async function handle(
    Message\IServerRequest $request,
  ): Awaitable<Message\IResponse> {
    $request_body = TypeSpec\of<this::Request>()
      ->assertType($request->getParsedBody());

    $version = $request_body['version'];
    $code = $request_body['code'];
    $configuration = $request_body['configuration'];

    $evaluator = await Service\Evaluator::get();

    $result = await $evaluator->evaluate($version, $code, $configuration);

    $database = await Service\Database::get();

    await $database->saveEvaluation($result);

    return Message\Response\redirect(Message\uri('/r/'.$result->identifier));
  }
}
