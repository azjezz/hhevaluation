namespace HHEvaluation\BuildStep;

use namespace HHEvaluation\Service;
use namespace HH\Lib\{C, Math, Vec};
use namespace Nuxed\Console\{Feedback, Output};

/**
 * Run database migrations
 */
final abstract class MigrationStep extends Step {
  const dict<string, vec<string>> MIGRATIONS = dict[
    'version:1' => vec[
      'CREATE TABLE IF NOT EXISTS evaluation_results (
        identifier VARCHAR(255) NOT NULL,
        code LONGTEXT NOT NULL,
        configuration LONGTEXT NOT NULL,
        version VARCHAR(255) NOT NULL,
        hhvm_version_output LONGTEXT NOT NULL,
        hhvm_exit_code INT NOT NULL,
        hhvm_stdout LONGTEXT NOT NULL,
        hhvm_stderr LONGTEXT NOT NULL,
        hh_client_version_output LONGTEXT NOT NULL,
        hh_client_exit_code INT NOT NULL,
        hh_client_stdout LONGTEXT NOT NULL,
        hh_client_stderr LONGTEXT NOT NULL,
        executed_at DATETIME NOT NULL
      );',
    ],
    'version:2' => vec[
      'CREATE TABLE IF NOT EXISTS code_sample (
        id INT NOT NULL AUTO_INCREMENT,
        code LONGTEXT NOT NULL,
        hh_configuration LONGTEXT NOT NULL,
        ini_configuration LONGTEXT NOT NULL,

        PRIMARY KEY (id)
      ) ENGINE=INNODB;',
      'CREATE TABLE IF NOT EXISTS runtime_result (
        id INT NOT NULL AUTO_INCREMENT,
        code_sample_id INT NOT NULL,
        version TEXT NOT NULL,
        detailed_version TEXT NOT NULL,
        exit_code INT NOT NULL,
        stdout_content TEXT NOT NULL,
        stderr_content TEXT NOT NULL,

        PRIMARY KEY (id),
        FOREIGN KEY (code_sample_id) REFERENCES code_sample(id)
      ) ENGINE=INNODB;',
      'CREATE TABLE IF NOT EXISTS type_checker_result (
        id INT NOT NULL AUTO_INCREMENT,
        code_sample_id INT NOT NULL,
        version TEXT NOT NULL,
        detailed_version TEXT NOT NULL,
        exit_code INT NOT NULL,
        stdout_content TEXT NOT NULL,
        stderr_content TEXT NOT NULL,

        PRIMARY KEY (id),
        FOREIGN KEY (code_sample_id) REFERENCES code_sample(id)
      ) ENGINE=INNODB;',
    ],
    'version:3' => vec[
      'ALTER TABLE runtime_result ADD COLUMN last_updated DATETIME DEFAULT CURRENT_TIMESTAMP',
      'ALTER TABLE type_checker_result ADD COLUMN last_updated DATETIME DEFAULT CURRENT_TIMESTAMP',
    ],
    'version:4' => vec[
      'CREATE TABLE IF NOT EXISTS task (
        id INT NOT NULL AUTO_INCREMENT,
        code_sample_id INT NOT NULL,
        version TEXT NOT NULL,
        executed TINYINT NOT NULL,

        PRIMARY KEY (id),
        FOREIGN KEY (code_sample_id) REFERENCES code_sample(id)
      ) ENGINE=INNODB;',
    ],
    'version:5' => vec[
      'DROP TABLE task;',
    ],
    'version:6' => vec[
      'CREATE TABLE IF NOT EXISTS code_sample_result (
        id INT NOT NULL AUTO_INCREMENT,
        code_sample_id INT NOT NULL,
        version TEXT NOT NULL,
        detailed_version TEXT NOT NULL,
        exit_code INT NOT NULL,
        stdout_content TEXT NOT NULL,
        stderr_content TEXT NOT NULL,
        runtime_detailed_version TEXT NOT NULL,
        runtime_exit_code INT NOT NULL,
        runtime_stdout TEXT NOT NULL,
        runtime_stderr TEXT NOT NULL,
        type_checker_detailed_version TEXT NOT NULL,
        type_checker_exit_code INT NOT NULL,
        type_checker_stdout TEXT NOT NULL,
        type_checker_stderr TEXT NOT NULL,
        last_updated  DATETIME DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (id),
        FOREIGN KEY (code_sample_id) REFERENCES code_sample(id)
      ) ENGINE=INNODB;',
      'DROP TABLE runtime_result',
      'DROP TABLE type_checker_result',
    ],
    'version:7' => vec[
      'CREATE TABLE IF NOT EXISTS container_reference (
        id INT NOT NULL AUTO_INCREMENT,
        container_id TEXT NOT NULL,
        version TEXT NOT NULL,
        status TEXT NOT NULL,
        PRIMARY KEY (id)
      ) ENGINE=INNODB;',
    ],
    'version:8' => vec[
      'DELETE FROM container_reference;',
      'DROP TABLE container_reference;',
    ],
  ];

  <<__Override>>
  public static async function run(
    Output\IOutput $output,
    bool $_production = false,
  ): Awaitable<void> {
    $count = Vec\map(self::MIGRATIONS, ($queries) ==> C\count($queries));
    $total = Math\sum($count);

    $progress = new Feedback\ProgressBarFeedback(
      $output,
      $total,
      '<fg=green>migrations</>  :',
    );

    await using ($database = await Service\Database::get()) {
      $connection = $database->connection;

      await $connection->query(
        'CREATE TABLE IF NOT EXISTS migrations (version VARCHAR(255) NOT NULL)',
      );

      foreach (static::MIGRATIONS as $version => $queries) {
        $already_exists = await $connection->queryf(
          'SELECT * FROM migrations WHERE version = %s',
          $version,
        );

        if (0 === $already_exists->numRows()) {
          foreach ($queries as $query) {
            concurrent {
              await $connection->query($query);
              await $progress->advance();
            }
          }

          await $connection->queryf(
            'INSERT INTO migrations (version) VALUES (%s)',
            $version,
          );
        } else {
          await $progress->advance(C\count($queries));
        }
      }
    }

    await $progress->finish();
  }
}
