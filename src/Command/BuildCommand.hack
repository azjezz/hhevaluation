namespace HHEvaluation\Command;

use namespace HH\Asio;
use namespace HH\Lib\Str;
use namespace Nuxed\Console\Feedback;
use namespace Nuxed\Console\Command;
use namespace Nuxed\Console\Input\Definition;
use namespace Nuxed\Process;
use namespace HHEvaluation\BuildStep;
use namespace HHEvaluation\HHVM;

final class BuildCommand extends Command\Command {
  const vec<classname<BuildStep\Step>> STEPS = vec[
    BuildStep\DockerStep::class,
    BuildStep\MigrationStep::class,
    BuildStep\BinaryStep::class,
    BuildStep\ModeStep::class,
    // BuildStep\RepoAuthStep::class,
  ];

  <<__Override>>
  public function configure(): void {
    $this
      ->setName('build')
      ->setDescription('Build HHEvaluation for deployment.')
      ->addFlag(new Definition\Flag('production', 'Build for production.'));
  }

  <<__Override>>
  public async function run(): Awaitable<int> {
    $production = $this->input->getFlag('production')->getValue(0) as int;
    foreach (static::STEPS as $step) {
      await $step::run($this->output, $production >= 1);
    }

    return Command\ExitCode::SUCCESS;
  }
}
