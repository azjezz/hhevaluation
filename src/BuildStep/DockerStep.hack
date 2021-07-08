namespace HHEvaluation\BuildStep;

use namespace HHEvaluation\HHVM;
use namespace HH\Asio;
use namespace HH\Lib\C;
use namespace Nuxed\Process;
use namespace Nuxed\Console\{Feedback, Output};

final abstract class DockerStep extends Step {
  /**
   * Pull docker image, with the give tag.
   */
  <<__Override>>
  public static async function run(
    Output\IOutput $output,
    bool $_production = false,
  ): Awaitable<void> {
    $versions = HHVM\Version::getValues();
    $progress = new Feedback\ProgressBarFeedback(
      $output,
      C\count($versions) * 3,
      '<fg=green>docker</>      :',
    );

    $operations = vec[];
    foreach ($versions as $version) {
      $operations[] = async {
        await $progress->advance();

        concurrent {
          await Process\execute(
            'docker',
            vec[
              'pull',
              'hhvm/hhvm:'.$version,
              '-q',
            ],
          );

          await $progress->advance();
        }

        await $progress->advance();
      };
    }

    await Asio\v($operations);
    await $progress->finish();
  }
}
