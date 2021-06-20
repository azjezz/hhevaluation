namespace HHEvaluation\Model;

use namespace HH\Lib\SQL;
use namespace HHEvaluation;
use namespace HHEvaluation\HHVM;

final class RuntimeResult extends AbstractModel {
  const type Structure = shape(
    'code_sample_id' => int,
    'version' => string,
    'detailed_version' => string,
    'exit_code' => int,
    'stdout_content' => string,
    'stderr_content' => string,
    'last_updated' => string,
  );

  public function isOutdated(): bool {
    if ($this->data['version'] === HHVM\Version::HHVM_NIGHTLY) {
      return HHEvaluation\Utils::getDueDaysFromString($this->data['last_updated']) >= 1;
    }

    if ($this->data['version'] === HHVM\Version::HHVM_LATEST) {
      return HHEvaluation\Utils::getDueDaysFromString($this->data['last_updated']) >= 4;
    }

    return false;
  }

  public static async function findOneByCodeSampleAndVersion(
    CodeSample $code_sample,
    HHVM\Version $version,
  ): Awaitable<?this> {
    return await static::findOneUsingQuery(
      new SQL\Query(
        'SELECT * FROM runtime_result WHERE code_sample_id = %d AND version = %s',
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
      'INSERT INTO runtime_result (code_sample_id, version, detailed_version, exit_code, stdout_content, stderr_content, last_updated) VALUES (%d, %s, %s, %d, %s, %s, %s)',
      $structure['code_sample_id'],
      $structure['version'],
      $structure['detailed_version'],
      $structure['exit_code'],
      $structure['stdout_content'],
      $structure['stderr_content'],
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
      'UPDATE code_sample SET code_sample_id = %d, version = %s, detailed_version = %s, exit_code = %d, stdout_content = %s, stderr_content = %s, last_updated = %s WHERE id = %d',
      $structure['code_sample_id'],
      $structure['version'],
      $structure['detailed_version'],
      $structure['exit_code'],
      $structure['stdout_content'],
      $structure['stderr_content'],
      $structure['last_updated'],
      $identifier,
    );
  }
}
