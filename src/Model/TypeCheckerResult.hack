namespace HHEvaluation\Model;

use namespace HH\Lib\SQL;
use namespace HHEvaluation\HHVM;

final class TypeCheckerResult extends AbstractModel {
  const type Structure = shape(
    'code_sample_id' => int,
    'version' => string,
    'detailed_version' => string,
    'exit_code' => int,
    'stdout_content' => string,
    'stderr_content' => string,
  );

  public static async function findOneByCodeSampleAndVersion(
    CodeSample $code_sample,
    HHVM\Version $version,
  ): Awaitable<?this> {
    return await static::findOneUsingQuery(
      new SQL\Query(
        'SELECT * FROM type_checker_result WHERE code_sample_id = %d AND version = %s',
        $code_sample->getIdentifier(),
        $version,
      ),
    );
  }

  protected static function getInsertQuery(
    this::Structure $structure,
  ): SQL\Query {
    return new SQL\Query(
      'INSERT INTO type_checker_result (code_sample_id, version, detailed_version, exit_code, stdout_content, stderr_content) VALUES (%d, %s, %s, %d, %s, %s)',
      $structure['code_sample_id'],
      $structure['version'],
      $structure['detailed_version'],
      $structure['exit_code'],
      $structure['stdout_content'],
      $structure['stderr_content'],
    );
  }

  protected static function getSelectQuery(
    this::IdentifierType $identifier,
  ): SQL\Query {
    return new SQL\Query(
      'SELECT * FROM type_checker_result WHERE id = %d',
      $identifier,
    );
  }

  protected static function getUpdateQuery(
    this::IdentifierType $identifier,
    this::Structure $structure,
  ): SQL\Query {
    return new SQL\Query(
      'UPDATE code_sample SET code_sample_id = %d, version = %s, detailed_version = %s, exit_code = %d, stdout_content = %s, stderr_content = %s WHERE id = %d',
      $structure['code_sample_id'],
      $structure['version'],
      $structure['detailed_version'],
      $structure['exit_code'],
      $structure['stdout_content'],
      $structure['stderr_content'],
      $identifier,
    );
  }
}
