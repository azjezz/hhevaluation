namespace HHEvaluation\BuildStep;

use namespace HH\Lib\File;
use namespace Nuxed\Console\{Feedback, Output};

final abstract class ModeStep extends Step {
  /**
   * Pull docker image, with the give tag.
   */
  <<__Override>>
  public static async function run(
    Output\IOutput $output,
    bool $production = false,
  ): Awaitable<void> {
    $progress = new Feedback\ProgressBarFeedback(
      $output,
      4,
      '<fg=green>mode</>        :',
    );

    await $progress->advance();
    $file = File\open_write_only(__DIR__.'/../../server.ini');
    await $progress->advance();
    $file->seek($file->getSize());
    await $progress->advance();
    await $file->writeAllAsync(
      "\nhhvm.env_variables[APP_MODE] = \"".
      ($production ? 'production' : 'development').
      "\"\n",
    );

    await $progress->finish();
  }
}
