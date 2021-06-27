namespace HHEvaluation;

use namespace HH\Lib\File;
use namespace Nuxed\{Environment, Process, Json};

/**
 * wrapper around the rust binary hh-exec
 */
final class HHExecute {
  const type Structure = shape(
    'runtime' => shape(
      'exit_code' => int,
      'stderr' => string,
      'stdout' => string,
      'detailed_version' => string,
    ),
    'type_checker' => shape(
      'exit_code' => int,
      'stderr' => string,
      'stdout' => string,
      'detailed_version' => string,
    ),
  );

  public static async function run(
    Model\CodeSample $code,
    HHVM\Version $version,
  ): Awaitable<Model\CodeSampleResult::Structure> {
    $binary = (Environment\get('HH_EXECUTE_PATH') as nonnull);

    using $code_file = File\temporary_file();
    using $ini_file = File\temporary_file();
    using $hh_file = File\temporary_file();

    concurrent {
      await $code_file->getHandle()
        ->writeAllAsync($code->getData()['code']);
      await $ini_file->getHandle()
        ->writeAllAsync($code->getData()['ini_configuration']);
      await $hh_file->getHandle()
        ->writeAllAsync($code->getData()['hh_configuration']);
    }

    list($stdout, $_) = await Process\execute($binary, vec[
      $version,
      $code_file->getHandle()->getPath(),
      $ini_file->getHandle()->getPath(),
      $hh_file->getHandle()->getPath(),
    ]);

    $result = Json\typed<this::Structure>($stdout);

    return shape(
      'code_sample_id' => $code->getIdentifier(),
      'version' => $version,

      'runtime_detailed_version' => $result['runtime']['detailed_version'],
      'runtime_exit_code' => $result['runtime']['exit_code'],
      'runtime_stdout' => $result['runtime']['stdout'],
      'runtime_stderr' => $result['runtime']['stderr'],

      'type_checker_detailed_version' =>
        $result['type_checker']['detailed_version'],
      'type_checker_exit_code' => $result['type_checker']['exit_code'],
      'type_checker_stdout' => $result['type_checker']['stdout'],
      'type_checker_stderr' => $result['type_checker']['stderr'],

      'last_updated' => Utils::getCurrentDatetimeString(),
    );
  }
}
