namespace HHEvaluation\Model;

use namespace HH\Lib\SQL;

final class CodeSample extends AbstractModel {
  const type Structure = shape(
    'code' => string,
    'hh_configuration' => string,
    'ini_configuration' => string,
  );

  public static async function findDuplicate(
    this::Structure $structure,
  ): Awaitable<?this> {
    return await static::findOneUsingQuery(new SQL\Query(
      'SELECT * FROM code_sample WHERE code = %s AND hh_configuration = %s AND ini_configuration = %s',
      $structure['code'],
      $structure['hh_configuration'],
      $structure['ini_configuration'],
    ));
  }

  <<__Override>>
  protected static function getInsertQuery(
    this::Structure $structure,
  ): SQL\Query {
    return new SQL\Query(
      'INSERT INTO code_sample (code, hh_configuration, ini_configuration) VALUES (%s, %s, %s)',
      $structure['code'],
      $structure['hh_configuration'],
      $structure['ini_configuration'],
    );
  }

  <<__Override>>
  protected static function getSelectQuery(
    this::IdentifierType $identifier,
  ): SQL\Query {
    return new SQL\Query(
      'SELECT * FROM code_sample WHERE id = %d',
      $identifier,
    );
  }

  <<__Override>>
  protected static function getUpdateQuery(
    this::IdentifierType $identifier,
    this::Structure $structure,
  ): SQL\Query {
    return new SQL\Query(
      'UPDATE code_sample SET code = %s, hh_configuration = %s, ini_configuration = %s WHERE id = %d',
      $structure['code'],
      $structure['hh_configuration'],
      $structure['ini_configuration'],
      $identifier,
    );
  }
}
