namespace HHEvaluation;

use namespace HH\Lib\Str;

final class Evaluator {
  public static async function getResult(
    Model\CodeSample $code_sample,
    HHVM\Version $version,
  ): Awaitable<Model\CodeSampleResult> {
    $result = await Model\CodeSampleResult::findOneByCodeSampleAndVersion(
      $code_sample,
      $version,
    );

    if (null !== $result) {
      return $result;
    }

    $result = await static::run($code_sample, $version);

    return await Model\CodeSampleResult::create($result);
  }

  public static async function run(
    Model\CodeSample $code_sample,
    HHVM\Version $version,
  ): Awaitable<Model\CodeSampleResult::Structure> {
    $container_id = await DockerEngine::findOrCreateContainerForVersion(
      $version,
    );

    $directory = Str\format('/home/%d', $code_sample->getIdentifier());

    concurrent {
      await DockerEngine::archive($container_id, $code_sample);

      list($_, $hhvm_version, $_) = await DockerEngine::exec(
        $container_id,
        vec['hhvm', '--version'],
        '/home',
        false,
      );

      list($_, $hh_version, $_) = await DockerEngine::exec(
        $container_id,
        vec['hh_server', '--version'],
        '/home',
        false,
      );
    }

    concurrent {
      list($hhvm_exit_code, $hhvm_stdout, $hhvm_stderr) =
        await DockerEngine::exec(
          $container_id,
          vec['hhvm', '-c', 'configuration.ini', 'main.hack'],
          $directory,
        );

      list($hh_exit_code, $hh_stdout, $hh_stderr) = await DockerEngine::exec(
        $container_id,
        vec['hh_server', '--check', '.'],
        $directory,
      );
    }

    return shape(
      'code_sample_id' => $code_sample->getIdentifier(),
      'version' => $version,

      'runtime_detailed_version' => $hhvm_version,
      'runtime_exit_code' => $hhvm_exit_code,
      'runtime_stdout' => $hhvm_stdout,
      'runtime_stderr' => $hhvm_stderr,

      'type_checker_detailed_version' => $hh_version,
      'type_checker_exit_code' => $hh_exit_code,
      'type_checker_stdout' => $hh_stdout,
      'type_checker_stderr' => $hh_stderr,

      'last_updated' => Utils::getCurrentDatetimeString(),
    );
  }
}
