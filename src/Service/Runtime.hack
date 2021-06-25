namespace HHEvaluation\Service;

use namespace HH\Lib\{C, Str, Vec};
use namespace Nuxed\Console\Command;
use namespace Nuxed\Http\Client;
use namespace Nuxed\Http\Message;
use namespace Nuxed\Json;
use namespace HHEvaluation;
use namespace HHEvaluation\Model;
use namespace HHEvaluation\HHVM;

final class Runtime {
  public static async function update(
    HHVM\Version $version,
    \DateTimeImmutable $latest_build_date,
  ): Awaitable<int> {
    $builds = await Model\RuntimeResult::findOutdated(
      $version,
      $latest_build_date,
    );

    $count = C\count($builds);
    if (0 !== $count) {
      $awaitables = vec[];
      await Vec\map_async($builds, async ($result) ==> {
        await using ($container = await HHVM\Container::run($version)) {
          $code_sample = await Model\CodeSample::findOne(
            $result->getData()['code_sample_id'],
          ) as nonnull;

          concurrent {
            $detailed_version = await $container->getRuntimeVersion();
            list($exit_code, $stdout, $stderr) =
              await $container->getRuntimeResult(
                $code_sample->getData()['code'],
                $code_sample->getData()['ini_configuration'],
              );
          }

          await $result->update(shape(
            'code_sample_id' => $code_sample->getIdentifier(),
            'version' => $version,
            'detailed_version' => $detailed_version,
            'exit_code' => $exit_code,
            'stdout_content' => $stdout,
            'stderr_content' => $stderr,
            'last_updated' => HHEvaluation\Utils::getCurrentDatetimeString(),
          ));
        }
      });
    }

    return $count;
  }

  public static async function run(
    Model\CodeSample $code_sample,
    HHVM\Version $version,
  ): Awaitable<Model\RuntimeResult> {
    await using ($container = await HHVM\Container::run($version)) {
      concurrent {
        $detailed_version = await $container->getRuntimeVersion();
        list($exit_code, $stdout, $stderr) = await $container->getRuntimeResult(
          $code_sample->getData()['code'],
          $code_sample->getData()['ini_configuration'],
        );
      }

      return await Model\RuntimeResult::create(
        shape(
          'code_sample_id' => $code_sample->getIdentifier(),
          'version' => $version,
          'detailed_version' => $detailed_version,
          'exit_code' => $exit_code,
          'stdout_content' => $stdout,
          'stderr_content' => $stderr,
          'last_updated' => HHEvaluation\Utils::getCurrentDatetimeString(),
        ),
      );
    }
  }
}
