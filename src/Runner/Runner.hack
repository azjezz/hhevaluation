namespace HHEvaluation\Runner;

use namespace HH\Lib\{File, SecureRandom, Str};
use namespace Nuxed\Process;

final class Runner {
  public function __construct(private string $directory) {}

  public async function run(Script $script): Awaitable<RuntimeResult> {
    $identifier = SecureRandom\string(
      10,
      '0123456789abcdefghijklmnopqrstuvwxyz',
    );
    $project = $this->directory.'/'.$identifier;

    \mkdir($project, 0777, true);

    await $this->writeFileAsync($project.'/main.hack', $script->code);

    await $this->buildDockerFile($project, $script->version);
    try {
      await Process\execute(
        'docker',
        vec['build', '-t', $identifier, $project],
      );

      $code = 0;
      list($stdout, $stderr) = await Process\execute(
        'docker',
        vec[
          'run',
          '--memory-reservation=150m',
          '--memory=200m',
          '--cpus=1',
          $identifier,
        ],
      );

      $content = $stdout.$stderr;
    } catch (Process\Exception\FailedExecutionException $e) {
      $code = $e->getExitCode();
      $content = $e->getStdoutContent().$e->getStderrContent();
    }

    return new RuntimeResult($code, Str\trim_left($content, "\n"));
  }

  private async function writeFileAsync(
    string $file,
    string $content,
  ): Awaitable<void> {
    $file = File\open_write_only($file, File\WriteMode::MUST_CREATE);
    await $file->writeAllAsync($content);
    $file->close();
  }

  private async function buildDockerFile(
    string $directory,
    HHVMVersion $version,
  ): Awaitable<void> {
    $docker_file_content = 'FROM hhvm/hhvm:'.$version."\n\n".
      "ADD main.hack /etc/hhvm/main.hack\n".
      "CMD [\"/usr/bin/hhvm\", \"/etc/hhvm/main.hack\"]\n";

    await $this->writeFileAsync($directory.'/Dockerfile', $docker_file_content);
  }
}
