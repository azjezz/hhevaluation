namespace HHEvaluation\BuildStep;

use namespace Nuxed\Console\Output;

<<
  __ConsistentConstruct,
  __Sealed(
    DockerStep::class,
    MigrationStep::class,
    ModeStep::class,
    RepoAuthStep::class,
  ),
>>
abstract class Step {
  abstract public static function run(
    Output\IOutput $output,
    bool $production = false,
  ): Awaitable<void>;
}
