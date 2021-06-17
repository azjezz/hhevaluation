namespace HHEvaluation\Handler;

use namespace HHEvaluation\Runner;
use namespace Nuxed\Http\{Handler, Message};
use namespace HH\Lib\{File, Str};

final class ExecuteHandler implements Handler\IHandler {
  public function __construct(private Runner\Runner $runner) {}

  public async function handle(
    Message\IServerRequest $request,
  ): Awaitable<Message\IResponse> {
    $script = new Runner\Script(
      $request->getParsedBody()['code'] ?? '',
      Runner\HHVMVersion::HHVM_LATEST, // For now, use latest
    );

    $result = await $this->runner->run($script);

    $file = File\open_read_only(__DIR__.'/../../templates/result.html');
    $content = await $file->readAllAsync()
      |> Str\replace_every_nonrecursive($$, dict[
        '{{ code }}' => \htmlspecialchars($script->code),
        '{{ result }}' => \htmlspecialchars($result->output),
      ]);

    return Message\Response\html($content);
  }
}
