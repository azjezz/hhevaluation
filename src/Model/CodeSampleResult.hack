namespace HHEvaluation\Model;

use namespace HH\Lib\SQL;
use namespace HHEvaluation;
use namespace HHEvaluation\HHVM;

final class CodeSampleResult extends AbstractModel {
  const type Structure = shape(
    'code_sample_id' => int,
    'version' => string,

    'runtime_detailed_version' => string,
    'runtime_exit_code' => int,
    'runtime_stdout' => string,
    'runtime_stderr' => string,

    'type_checker_detailed_version' => string,
    'type_checker_exit_code' => int,
    'type_checker_stdout' => string,
    'type_checker_stderr' => string,

    'last_updated' => string,
  );

  /**
   * Find the first $limit results where the version is $version,
   * and last_updated is lower than $lastest_build_date.
   */
  public static async function findOutdated(
    HHVM\Version $version,
    \DateTimeImmutable $latest_build_date,
    int $limit = 100,
  ): Awaitable<vec<this>> {
    return await static::findUsingQuery(new SQL\Query(
      'SELECT * FROM code_sample_result WHERE DATE(last_updated) < %s AND version = %s LIMIT %d',
      $latest_build_date->format('Y-m-d'),
      $version,
      $limit,
    ));
  }

  public static async function findOneByCodeSampleAndVersion(
    CodeSample $code_sample,
    HHVM\Version $version,
  ): Awaitable<?this> {
    return await static::findOneUsingQuery(
      new SQL\Query(
        'SELECT * FROM code_sample_result WHERE code_sample_id = %d AND version = %s',
        $code_sample->getIdentifier(),
        $version,
      ),
    );
  }

  <<__Override>>
  static protected function getInsertQuery(
    this::Structure $structure,
  ): SQL\Query {
    return new SQL\Query(
      'INSERT INTO code_sample_result (
        code_sample_id,
        version,

        runtime_detailed_version,
        runtime_exit_code,
        runtime_stdout,
        runtime_stderr,

        type_checker_detailed_version,
        type_checker_exit_code,
        type_checker_stdout,
        type_checker_stderr,

        last_updated

      ) VALUES (%d, %s, %s, %d, %s, %s, %s, %d, %s, %s, %s)',
      $structure['code_sample_id'],
      $structure['version'],

      $structure['runtime_detailed_version'],
      $structure['runtime_exit_code'],
      $structure['runtime_stdout'],
      $structure['runtime_stderr'],

      $structure['type_checker_detailed_version'],
      $structure['type_checker_exit_code'],
      $structure['type_checker_stdout'],
      $structure['type_checker_stderr'],

      $structure['last_updated'],
    );
  }

  <<__Override>>
  static protected function getSelectQuery(
    this::IdentifierType $identifier,
  ): SQL\Query {
    return new SQL\Query(
      'SELECT * FROM runtime_result WHERE id = %d',
      $identifier,
    );
  }

  <<__Override>>
  protected static function getUpdateQuery(
    this::IdentifierType $identifier,
    this::Structure $structure,
  ): SQL\Query {
    return new SQL\Query(
      'UPDATE code_sample_result SET
        code_sample_id = %d,
        version = %s,
        runtime_detailed_version = %s,
        runtime_exit_code = %d,
        runtime_stdout = %s,
        runtime_stderr = %s,
        type_checker_detailed_version = %s,
        type_checker_exit_code = %d,
        type_checker_stdout = %s,
        type_checker_stderr = %s,
        last_updated = %s
      WHERE id = %d',
      $structure['code_sample_id'],
      $structure['version'],

      $structure['runtime_detailed_version'],
      $structure['runtime_exit_code'],
      $structure['runtime_stdout'],
      $structure['runtime_stderr'],

      $structure['type_checker_detailed_version'],
      $structure['type_checker_exit_code'],
      $structure['type_checker_stdout'],
      $structure['type_checker_stderr'],

      $structure['last_updated'],
      $identifier,
    );
  }
}
