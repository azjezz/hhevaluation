
namespace HHEvaluation\Handler\TypeChecker;

use namespace HHEvaluation;
use namespace HHEvaluation\{HHVM, Model, Service};
use namespace Nuxed\Http\{Exception, Handler, Message};

final class ResultHandler implements Handler\IHandler {
  public async function handle(
    Message\IServerRequest $request,
  ): Awaitable<Message\IResponse> {
    $identifier = (int)$request->getAttribute<string>('id');
    $version = HHVM\Version::coerce($request->getAttribute<string>('version'));

    $code_sample = await Model\CodeSample::findOne($identifier);
    if (null === $code_sample || null === $version) {
      throw new Exception\NotFoundException();
    }

    $result = await Model\TypeCheckerResult::findOneByCodeSampleAndVersion(
      $code_sample,
      $version,
    );

    if (null === $result) {
      $result = await Service\TypeChecker::run($code_sample, $version);
    }

    return Message\Response\json($result->toDict())
      |> Message\Response\with_cache_control_directive($$, 'must-revalidate')
      |> Message\Response\with_cache_control_directive($$, 'public')
      |> Message\Response\with_max_age($$, 86400)
      |> Message\Response\with_last_modified(
        $$,
        HHEvaluation\Utils::getDateTimeFromString(
          $result->getData()['last_updated'],
        )->getTimestamp(),
      );
  }
}
