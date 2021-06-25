

namespace HHEvaluation\Command\Database;

use namespace HH\Lib\Str;
use namespace HHEvaluation\Service;
use namespace Nuxed\Console\Command;

final class MigrateCommand extends Command\Command {
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
  ];

  <<__Override>>
  public function configure(): void {
    $this
      ->setName('database:migrate')
      ->setDescription('Migrate the database');
  }

  <<__Override>>
  public async function run(): Awaitable<int> {
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
          await $this->output->writeln('');
          await $this->output
            ->writeln(
              Str\format('<fg=yellow>running "%s" migration</>', $version),
            );
          await $this->output->writeln('');

          foreach ($queries as $query) {
            concurrent {
              await $this->output
                ->writeln(Str\format('   <fg=green>-></> %s', $query));
              await $connection->query($query);
              await $this->output->writeln('');
            }
          }

          await $this->output
            ->writeln(
              '<fg=green>------------------------------------------------</>',
            );

          await $connection->queryf(
            'INSERT INTO migrations (version) VALUES (%s)',
            $version,
          );
        }
      }
    }

    await $this->output->writeln('');
    await $this->output->writeln('<fg=green>done.</>');

    return Command\ExitCode::SUCCESS;
  }
}
