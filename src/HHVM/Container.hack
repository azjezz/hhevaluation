
namespace HHEvaluation\HHVM;

use namespace HH\Lib\{File, SecureRandom, Vec, Str};
use namespace Nuxed\Process;

final class Container {
  private function __construct(private string $container_id) {}

  public static async function pull(Version $version): Awaitable<void> {
    $container = await self::run($version, __DIR__);
    await $container->kill();
  }

  public static async function run(
    Version $version,
    string $directory,
  ): Awaitable<this> {
    list($stdout, $stderr) = await Process\execute(
      'docker',
      vec[
        'run',
        '-d',
        '-it',
        '--memory-reservation=1500m',
        '--memory=1800m',
        '--cpus=1',
        '-v',
        $directory.':/tmp/hhevaluation/',
        'hhvm/hhvm:'.$version,
      ],
    );

    $instance = new self(Str\trim($stdout));
    do {
      list($code, $_, $_) = await $instance->execute(vec['sleep', '0']);
    } while ($code !== 0);

    return $instance;
  }

  public async function execute(
    vec<string> $arguments,
  ): Awaitable<(int, string, string)> {
    try {
      list($stdout, $stderr) = await Process\execute('docker', Vec\concat(
        vec[
          'exec',
          '-w',
          '/tmp/hhevaluation/',
          $this->container_id,
        ],
        $arguments,
      ));

      return tuple(0, $stdout, $stderr);
    } catch (Process\Exception\FailedExecutionException $e) {
      return tuple(
        $e->getExitCode(),
        $e->getStdoutContent(),
        $e->getStderrContent(),
      );
    }
  }

  public async function kill(): Awaitable<void> {
    list($stdout, $stderr) = await Process\execute(
      'docker',
      vec[
        'kill',
        $this->container_id,
      ],
    );
  }
}
