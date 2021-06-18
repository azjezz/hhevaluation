namespace HHEvaluation\Service;

use namespace HH\Lib\{IO, File};
use namespace Nuxed\Json;
use namespace HHEvaluation;
use namespace HHEvaluation\ValueObject;

final class Database {
  const type Configuration = shape(
    'host' => string,
    'port' => int,
    'user' => string,
    'password' => string,
    'database' => string,
  );

  private static ?Database $instance = null;

  public function __construct(public \AsyncMysqlConnection $connection) {
  }

  public static async function get(): Awaitable<Database> {
    if (null !== self::$instance) {
      return self::$instance;
    }

    $configuration = await HHEvaluation\ConfigurationLoader::load<
      this::Configuration,
    >('database');

    $connection = await \AsyncMysqlClient::connect(
      $configuration['host'],
      $configuration['port'],
      $configuration['database'],
      $configuration['user'],
      $configuration['password'],
    );

    self::$instance = new self($connection);

    return self::$instance;
  }

  public async function findEvaluation(
    string $identifier,
  ): Awaitable<?ValueObject\EvaluationResult> {

    $res = await $this->connection->queryf(
      'SELECT * FROM evaluation_results WHERE identifier = %s',
      $identifier,
    );

    if (1 !== $res->numRows()) {
      return null;
    }

    $result = $res->dictRowsTyped()[0];

    return new ValueObject\EvaluationResult(
      $result['identifier'] as string,
      $result['code'] as string,
      $result['configuration'] as string,
      $result['version'] as string,
      $result['hhvm_version_output'] as string,
      $result['hhvm_exit_code'] as int,
      $result['hhvm_stdout'] as string,
      $result['hhvm_stderr'] as string,
      $result['hh_client_version_output'] as string,
      $result['hh_client_exit_code'] as int,
      $result['hh_client_stdout'] as string,
      $result['hh_client_stderr'] as string,
      \DateTimeImmutable::createFromFormat(
        'Y-m-d H:i:s',
        $result['executed_at'] as string,
        new \DateTimeZone('GMT'),
      ),
    );
  }

  public async function saveEvaluation(
    ValueObject\EvaluationResult $result,
  ): Awaitable<void> {
    $res = await $this->connection->queryf(
      'INSERT INTO evaluation_results VALUES(%s, %s, %s, %s, %s, %d, %s, %s, %s, %d, %s, %s, %s)',
      $result->identifier,
      $result->code,
      $result->configuration,
      $result->version,
      $result->hhvm_version_output,
      $result->hhvm_exit_code,
      $result->hhvm_stdout,
      $result->hhvm_stderr,
      $result->hh_client_version_output,
      $result->hh_client_exit_code,
      $result->hh_client_stdout,
      $result->hh_client_stderr,
      (string)$result->executed_at->format('Y-m-d H:i:s'),
    );
  }
}
