namespace HHEvaluation\Command;

use namespace HH\Lib\{C, Str, Vec};
use namespace Nuxed\Console\Command;
use namespace Nuxed\Process;
use namespace HHEvaluation;
use namespace HHEvaluation\{HHVM, Model};

final class NightlyCommand extends Command\Command {
  <<__Override>>
  public function configure(): void {
    $this
      ->setName('update:nightly')
      ->setDescription('Update nightly builds to the latest release.');
  }

  <<__Override>>
  public async function run(): Awaitable<int> {
    $latest_build_date = await HHVM\API::getNightlyBuildDate();

    await Process\execute('docker', vec['pull', 'hhvm/hhvm:nightly']);

    $builds = await Model\CodeSampleResult::findOutdated(
      HHVM\Version::HHVM_NIGHTLY,
      $latest_build_date,
    );

    $count = C\count($builds);
    if (0 !== $count) {
      await Vec\map_async($builds, async ($result) ==> {
        $code_sample = await Model\CodeSample::findOne(
          $result->getData()['code_sample_id'],
        ) as nonnull;

        $structure = await HHEvaluation\Evaluator::run(
          $code_sample,
          HHVM\Version::HHVM_NIGHTLY,
        );

        await $result->update($structure);
      });
    }

    await $this->output
      ->writeLine(Str\format(
        '- updated <fg=cyan>%d</> build(s) to nightly-%s.',
        $count,
        $latest_build_date->format('Y-m-d'),
      ));

    return Command\ExitCode::SUCCESS;
  }
}
