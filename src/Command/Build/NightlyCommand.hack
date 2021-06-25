namespace HHEvaluation\Command\Build;

use namespace HH\Lib\Str;
use namespace Nuxed\Console\Command;
use namespace HHEvaluation\{Service, HHVM};

final class NightlyCommand extends Command\Command {
  <<__Override>>
  public function configure(): void {
    $this
      ->setName('build:nightly')
      ->setDescription('Update nightly builds to the latest release.');
  }

  <<__Override>>
  public async function run(): Awaitable<int> {
    $result = await HHVM\API::getNightlyBuildDate();

    await HHVM\Container::pull(HHVM\Version::HHVM_NIGHTLY);

    concurrent {
      $runtime_count = await Service\Runtime::update(
        HHVM\Version::HHVM_NIGHTLY,
        $result,
      );

      $type_checker_count = await Service\TypeChecker::update(
        HHVM\Version::HHVM_NIGHTLY,
        $result,
      );
    }

    await $this->output
      ->writeln(Str\format(
        '- updated <fg=cyan>%d</> runtime build(s) to nightly-%s.',
        $runtime_count,
        $result->format('Y-m-d'),
      ));

    await $this->output
      ->writeln(Str\format(
        '- updated <fg=cyan>%d</> type checker build(s) to nightly-%s.',
        $type_checker_count,
        $result->format('Y-m-d'),
      ));

    return Command\ExitCode::SUCCESS;
  }
}
