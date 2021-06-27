namespace HHEvaluation\BuildStep;

use namespace HHEvaluation\HHVM;
use namespace HH\Asio;
use namespace HH\Lib\{C, File, Str, Vec};
use namespace Nuxed\Process;
use namespace Nuxed\Console\Output;
use namespace Nuxed\Console\Feedback;

final abstract class BinaryStep extends Step {
  /**
   * Pull docker image, with the give tag.
   */
  public static async function run(
    Output\IOutput $output,
    bool $production = false,
  ): Awaitable<void> {
    $progress = new Feedback\ProgressBarFeedback(
      $output,
      7,
      '<fg=green>binary</>      :',
    );

    $args = vec[
      'build',
      '--manifest-path',
      'rust/Cargo.toml',
    ];

    if ($production) {
      $args[] = '--release';
      $args[] = '--offline';
    }

    concurrent {
      await Process\execute('cargo', $args, __DIR__.'/../../');

      await async {
        await $progress->advance();
        await $progress->advance();
      };
    }

    $executable_directory = __DIR__.'/../../rust/target/release/hh-execute';
    await $progress->advance();
    $file = File\open_write_only(__DIR__.'/../../server.ini');
    await $progress->advance();
    $file->seek($file->getSize());
    await $progress->advance();
    await $file->writeAllAsync(
      "\nhhvm.env_variables[HH_EXECUTE_PATH] = \"".
      \realpath($executable_directory).
      "\"\n",
    );
    await $progress->advance();

    await $progress->finish();
  }
}
