namespace HHEvaluation\Command;

use namespace HH\Lib\{Str, Vec};
use namespace Nuxed\Console\Command;
use namespace HHEvaluation;

final class ShutdownCommand extends Command\Command {
  <<__Override>>
  public function configure(): void {
    $this
      ->setName('docker:shutdown')
      ->setDescription('Shutdown all running containers.');
  }

  <<__Override>>
  public async function run(): Awaitable<int> {
    $containers = await HHEvaluation\DockerEngine::findAllRunningContainers();
    await Vec\map_async($containers, async ($container) ==> {
      await $this->output
        ->writeLine(Str\format('Stopping container "%s".', $container));

      await HHEvaluation\DockerEngine::forceDeleteContainer($container);
    });

    return Command\ExitCode::SUCCESS;
  }
}
