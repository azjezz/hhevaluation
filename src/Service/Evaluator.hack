namespace HHEvaluation\Service;

use namespace HH\Lib\{File, SecureRandom};
use namespace HHEvaluation;
use namespace HHEvaluation\{HHVM, ValueObject};

final class Evaluator {
  const type Configuration = shape(
    'directory' => string,
  );

  private static ?Evaluator $instance = null;

  public function __construct(private string $directory)[] {}

  public static async function get(): Awaitable<Evaluator> {
    if (null !== self::$instance) {
      return self::$instance;
    }

    self::$instance = new self(\realpath(__DIR__.'/../../var') as string);

    return self::$instance;
  }

  public async function evaluate(
    HHVM\Version $version,
    string $code,
    string $configuration,
  ): Awaitable<ValueObject\EvaluationResult> {

    $identifier = SecureRandom\string(
      14,
      'azertyqsdfghjklmuiopwxcvbn1234567890',
    );

    $directory = $this->directory.'/'.$identifier;
    \mkdir($directory);
    $container = await HHVM\Container::run($version, $directory);

    $code_file = File\open_read_write($directory.'/main.hack');
    $configuration_file = File\open_read_write($directory.'/.hhconfig');
    concurrent {
      await $code_file->writeAllAsync($code);
      await $configuration_file->writeAllAsync($configuration);
    }

    concurrent {
      await $container->execute(vec['hh_server', 'start', '-d', '.']);

      list($_, $hh_client_version, $_) = await $container->execute(
        vec['hh_client', '--version'],
      );

      list($hh_client_exit_code, $hh_client_stdout, $hh_client_stderr) =
        await $container->execute(vec['hh_client', 'main.hack']);

      list($_, $hhvm_version, $_) = await $container->execute(
        vec['hhvm', '--version'],
      );
      list($hhvm_exit_code, $hhvm_stdout, $hhvm_stderr) =
        await $container->execute(vec['hhvm', 'main.hack']);
    }

    $code_file->close();
    $configuration_file->close();

    \unlink($code_file->getPath());
    \unlink($configuration_file->getPath());
    \rmdir($directory);

    return new ValueObject\EvaluationResult(
      $identifier,
      $code,
      $configuration,
      $version,
      $hhvm_version,
      $hhvm_exit_code,
      $hhvm_stdout,
      $hhvm_stderr,
      $hh_client_version,
      $hh_client_exit_code,
      $hh_client_stdout,
      $hh_client_stderr,
      new \DateTimeImmutable('now', new \DateTimeZone('GMT')),
    );
  }
}
