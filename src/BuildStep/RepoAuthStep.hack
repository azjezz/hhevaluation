namespace HHEvaluation\BuildStep;

use namespace HHEvaluation\HHVM;
use namespace HH\Asio;
use namespace HH\Lib\{C, File, Str, Vec};
use namespace Nuxed\Process;
use namespace Nuxed\Console\Output;
use namespace Nuxed\Console\Feedback;

final abstract class RepoAuthStep extends Step {
  /**
   * Pull docker image, with the give tag.
   */
  public static async function run(
    Output\IOutput $output,
    bool $production = false,
  ): Awaitable<void> {
    $progress = new Feedback\ProgressBarFeedback(
      $output,
      6,
      '<fg=green>repo-auth</>   :',
    );

    if (!$production) {
      await $progress->finish();

      return;
    }

    // hhvm --hphp -t hhbc --input-dir . -o build
    await Process\execute(
      'hhvm',
      vec[
        '--hphp',
        '-t',
        'hhbc',
        '--input-dir',
        '.',
        '-o',
        'build',
      ],
      __DIR__.'/../../',
    );
    await $progress->advance();

    $executable_directory = __DIR__.'/../../rust/target/release/hh-execute';
    await $progress->advance();
    $file = File\open_write_only(__DIR__.'/../../server.ini');
    await $progress->advance();
    $file->seek($file->getSize());
    await $progress->advance();
    await $file->writeAllAsync("\nhhvm.repo.authoritative = true");
    await $progress->advance();
    await $file->writeAllAsync(
      "\nhhvm.repo.central.path = \"".
      \realpath(__DIR__.'/../../build/hhvm.hhbc').
      "\"\n",
    );

    await $progress->finish();
  }
}
