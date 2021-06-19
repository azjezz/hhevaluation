
namespace HHEvaluation\Command;

use namespace HH\Lib\Str;
use namespace Nuxed\Console\Command;
use namespace HHEvaluation;
use namespace HHEvaluation\{HHVM, Service};

final class SetupCommand extends Command\Command {
  <<__Override>>
  public function configure(): void {
    $this
      ->setName('hhevaluation:setup')
      ->setDescription('Setup HHEvaluation environment.');
  }

  <<__Override>>
  public async function run(): Awaitable<int> {
    // pull docker images.
    foreach (HHVM\Version::getValues() as $value) {
      concurrent {
        await $this->output
          ->write(Str\format('<fg=yellow>Pulling HHVM %s...</> ', $value));
        await HHVM\Container::pull($value);
      }

      await $this->output->writeln('<fg=green>done.</>');
    }

    // Connect to the database.
    concurrent {
      await $this->output->writeln('');
      await $this->output
        ->write('<fg=yellow>Connecting to the database...</> ');

      $connection = await Service\Database::get()
        |> $$->connection;
    }

    await $this->output->writeln('<fg=green>done.</>');

    // Set up the database structure.
    concurrent {
      await $this->output->write('<fg=yellow>Setting up the database...</> ');
      await $connection->query(<<<SQL
CREATE TABLE IF NOT EXISTS evaluation_results (
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
);
SQL
      );
    }

    await $this->output->writeln('<fg=green>done.</>');

    return Command\ExitCode::SUCCESS;
  }
}
