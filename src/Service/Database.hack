
namespace HHEvaluation\Service;

use namespace HH\Lib\Str;
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
}
