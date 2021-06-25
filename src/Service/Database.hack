
namespace HHEvaluation\Service;

use namespace HHEvaluation;

final class Database implements \IAsyncDisposable {
  const type Configuration = shape(
    'host' => string,
    'port' => int,
    'user' => string,
    'password' => string,
    'database' => string,
  );

  public function __construct(public \AsyncMysqlConnection $connection) {
  }

  <<__ReturnDisposable>>
  public static async function get(): Awaitable<Database> {
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

    return new self($connection);
  }

  public async function __disposeAsync(): Awaitable<void> {
    $this->connection->close();
  }
}
