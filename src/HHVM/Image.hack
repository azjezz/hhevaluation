namespace HHEvaluation\HHVM;

use namespace HH\Lib\{File, SecureRandom, Vec, Str};
use namespace Nuxed\Process;

final class Image {
  private function __construct(private Version $version) {}

  public static function create(Version $version): this {
    return new self($version);
  }

  public async function execute(
    string $directory,
    vec<string> $arguments,
  ): Awaitable<(int, string, string)> {
    try {
      list($stdout, $stderr) = await Process\execute(
        'docker',
        Vec\concat(
          vec[
            'run',
            '--memory-reservation=1500m',
            '--memory=1800m',
            '--cpus=1',
            '--rm',
            '-w',
            $directory,
            '-v',
            $directory.':'.$directory,
            'hhvm/hhvm:'.$this->version,
          ],
          $arguments,
        ),
      );

      return tuple(0, $stdout, $stderr);
    } catch (Process\Exception\FailedExecutionException $e) {
      return tuple(
        $e->getExitCode(),
        $e->getStdoutContent(),
        $e->getStderrContent(),
      );
    }
  }
}
