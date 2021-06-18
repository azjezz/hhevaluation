namespace HHEvaluation;

use namespace HH\Lib\{IO, File};
use namespace Nuxed\Json;

final class ConfigurationLoader {
  public static async function load<<<__Enforceable>> reify T>(
    string $entry,
  ): Awaitable<T> {
    $configuration_file = File\open_read_only(
      __DIR__.'/../config/'.$entry.'.json',
    );

    $configuration_json = await $configuration_file->readAllAsync();
    $configuration_file->close();

    return Json\typed<T>($configuration_json);
  }
}
