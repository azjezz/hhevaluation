namespace HHEvaluation\Handler;

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

    $result = await Model\CodeSampleResult::findOneByCodeSampleAndVersion(
      $code_sample,
      $version,
    );


    if ($result is null) {
      $structure = await HHEvaluation\HHExecute::run($code_sample, $version);
      $result = await Model\CodeSampleResult::create($structure);
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
