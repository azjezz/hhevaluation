
namespace HHEvaluation\Handler\TypeChecker;

use namespace HHEvaluation;
use namespace HHEvaluation\{Model, HHVM, Service};
use namespace Nuxed\Http\{Handler, Message, Exception};

final class ResultHandler implements Handler\IHandler {
  const type Request = shape(
    'code' => string,
    'configuration' => string,
    'version' => HHVM\Version,
    ...
  );

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
      $container = await HHVM\Container::run($version);
      $detailed_version = await $container->getTypeCheckerVersion();
      list($exit_code, $stdout, $stderr) =
        await $container->getTypeCheckerResult(
          $code_sample->getData()['code'],
          $code_sample->getData()['hh_configuration'],
        );

      $result = await Model\TypeCheckerResult::create(shape(
        'code_sample_id' => $code_sample->getIdentifier(),
        'version' => $version,
        'detailed_version' => $detailed_version,
        'exit_code' => $exit_code,
        'stdout_content' => $stdout,
        'stderr_content' => $stderr,
      ));
    } else if (
      $version === HHVM\Version::HHVM_NIGHTLY ||
      $version === HHVM\Version::HHVM_LATEST
    ) {
      // ensure that nightly/latest result is up to date.
      $container = await HHVM\Container::run($version);
      $detailed_version = await $container->getTypeCheckerVersion();
      if ($detailed_version !== $result->getData()['detailed_version']) {
        // our nightly result is outdated, let's re-run it.
        list($exit_code, $stdout, $stderr) =
          await $container->getTypeCheckerResult(
            $code_sample->getData()['code'],
            $code_sample->getData()['hh_configuration'],
          );

        $result = await $result->update(shape(
          'code_sample_id' => $code_sample->getIdentifier(),
          'version' => $version,
          'detailed_version' => $detailed_version,
          'exit_code' => $exit_code,
          'stdout_content' => $stdout,
          'stderr_content' => $stderr,
        ));
      }
    }

    return Message\Response\json($result->toDict());
  }
}
