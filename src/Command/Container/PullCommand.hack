
namespace HHEvaluation\Command\Container;

use namespace HH\Lib\Str;
use namespace Nuxed\Console\Command;
use namespace HHEvaluation;
use namespace HHEvaluation\{HHVM, Service};

final class PullCommand extends Command\Command {
  <<__Override>>
  public function configure(): void {
    $this
      ->setName('container:pull')
      ->setDescription('Pull HHVM docker containers.');
  }

  <<__Override>>
  public async function run(): Awaitable<int> {
    $lastOperation = async {
    };

    foreach (HHVM\Version::getValues() as $value) {
      $lastOperation = async {
        await $lastOperation;

        concurrent {
          await $this->output
            ->writeln(Str\format('<fg=yellow>Pulling HHVM %s...</> ', $value));
          await HHVM\Container::pull($value);
        }
      };
    }

    await $lastOperation;
    await $this->output->writeln('');
    await $this->output->writeln('<fg=green>done.</>');

    return Command\ExitCode::SUCCESS;
  }
}
