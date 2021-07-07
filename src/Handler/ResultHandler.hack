namespace HHEvaluation\Handler;

use namespace HH\Asio;
use namespace HHEvaluation;
use namespace HHEvaluation\{HHVM, Model};
use namespace Nuxed\Http\{Exception, Handler, Message};

final class ResultHandler implements Handler\IHandler {
  public async function handle(
    Message\IServerRequest $request,
  ): Awaitable<Message\IResponse> {
    $identifier = (int)$request->getAttribute<string>('id');

    $code_sample = await Model\CodeSample::findOne($identifier);
    if (null === $code_sample) {
      throw new Exception\NotFoundException();
    }

    $results = dict[];
    foreach (HHVM\Version::getValues() as $version) {
      $results[$version] = async {
        return await HHEvaluation\Evaluator::getResult($code_sample, $version)
          |> $$->toDict();
      };
    }

    $results = await Asio\m($results);

    return Message\Response\json($results)
      |> Message\Response\with_cache_control_directive($$, 'must-revalidate')
      |> Message\Response\with_cache_control_directive($$, 'public')
      |> Message\Response\with_max_age($$, 86400);
  }
}
