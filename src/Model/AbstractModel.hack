namespace HHEvaluation\Model;

use namespace HH\Lib\{C, SQL, Vec};
use namespace HHEvaluation\Service;
use namespace Facebook\TypeSpec;

<<__ConsistentConstruct, __Sealed(CodeSample::class, CodeSampleResult::class)>>
abstract class AbstractModel {
  const string IdentifierColumn = 'id';

  const type IdentifierType = int;

  <<__Reifiable>>
  abstract const type Structure as shape(
    ...
  );

  final public function __construct(
    protected int $identifier,
    protected this::Structure $data,
  ) {}

  public function getIdentifier(): int {
    return $this->identifier;
  }

  public function getData(): this::Structure {
    return $this->data;
  }

  public function toDict(): dict<string, mixed> {
    $dict = \HH\Shapes::toDict($this->getData());

    return TypeSpec\dict(TypeSpec\string(), TypeSpec\mixed())
      ->assertType($dict);
  }

  protected static async function findOneUsingQuery(
    SQL\Query $query,
  ): Awaitable<?this> {
    $results = await self::findUsingQuery($query);
    if (C\count($results) === 0) {
      return null;
    }

    return $results[0];
  }

  protected static async function findUsingQuery(
    SQL\Query $query,
  ): Awaitable<vec<this>> {
    return await static::runQuery($query)
      |> $$->dictRowsTyped()
      |> Vec\map(
        $$,
        ($row) ==> new static(
          TypeSpec\int()->coerceType($row[static::IdentifierColumn]),
          TypeSpec\of<this::Structure>()->coerceType($row),
        ),
      );
  }

  public static async function findOne(
    this::IdentifierType $identifier,
  ): Awaitable<?this> {
    return await static::findOneUsingQuery(static::getSelectQuery($identifier));
  }

  public static async function create(
    this::Structure $structure,
  ): Awaitable<this> {
    $result = await static::runQuery(static::getInsertQuery($structure));

    return new static($result->lastInsertId(), $structure);
  }

  public async function update(this::Structure $structure): Awaitable<this> {
    await static::runQuery(
      static::getUpdateQuery($this->identifier, $structure),
    );

    $this->data = $structure;

    return $this;
  }

  protected static async function runQuery(
    SQL\Query $query,
  ): Awaitable<\AsyncMysqlQueryResult> {
    await using ($database = await Service\Database::get()) {
      $connection = $database->connection;
      $result = await $connection->queryAsync($query);

      return $result;
    }
  }

  abstract protected static function getInsertQuery(
    this::Structure $structure,
  ): SQL\Query;

  abstract protected static function getSelectQuery(
    this::IdentifierType $identifier,
  ): SQL\Query;

  abstract protected static function getUpdateQuery(
    this::IdentifierType $identifier,
    this::Structure $structure,
  ): SQL\Query;
}
