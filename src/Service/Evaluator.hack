namespace HHEvaluation\Service;

use namespace HH\Lib\File;
use namespace HH\Lib\SecureRandom;
use namespace HH\Lib\Str;
use namespace Nuxed\Json;
use namespace HHEvaluation;
use namespace HHEvaluation\ValueObject;
use namespace HHEvaluation\HHVM;

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

    $configuration = await HHEvaluation\ConfigurationLoader::load<
      this::Configuration,
    >('evaluator');

    self::$instance = new self($configuration['directory']);

    return self::$instance;
  }

  public async function evaluate(
    HHVM\Version $version,
    string $code,
    string $configuration,
  ): Awaitable<ValueObject\EvaluationResult> {
    $image = HHVM\Image::create($version);

    $identifier = SecureRandom\string(
      14,
      'azertyqsdfghjklmuiopwxcvbn1234567890',
    );

    $directory = $this->directory.'/'.$identifier;

    \mkdir($directory);

    $code_file = File\open_read_write($directory.'/main.hack');
    $configuration_file = File\open_read_write($directory.'/.hhconfig');

    await $code_file->writeAllAsync($code);
    await $configuration_file->writeAllAsync($configuration);

    list($_, $hh_client_version, $_) = await $image->execute(
      $directory,
      vec['hh_client', '--version'],
    );
    list($hh_client_exit_code, $hh_client_stdout, $hh_client_stderr) =
      await $image->execute($directory, vec['hh_client', 'main.hack']);

    list($_, $hhvm_version, $_) = await $image->execute(
      $directory,
      vec['hhvm', '--version'],
    );
    list($hhvm_exit_code, $hhvm_stdout, $hhvm_stderr) = await $image->execute(
      $directory,
      vec['hhvm', 'main.hack'],
    );

    $code_file->close();
    $configuration_file->close();

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
