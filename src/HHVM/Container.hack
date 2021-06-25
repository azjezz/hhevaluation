
namespace HHEvaluation\HHVM;

use namespace HH\Lib\{File, Str, Vec};
use namespace Nuxed\Process;

final class Container implements \IAsyncDisposable {
  const int RUNTIME_TIMEOUT = 30;
  const int TYPE_CHECKER_TIMEOUT = 30;

  private function __construct(public string $container_id) {}

  /**
   * Pull HHVM image for the given version.
   */
  public static async function pull(Version $version): Awaitable<void> {
    await Process\execute(
      'docker',
      vec[
        'pull',
        'hhvm/hhvm:'.$version,
      ],
    );
  }

  /**
   * Create a new docker container for the given HHVM version.
   */
  <<__ReturnDisposable>>
  public static async function run(Version $version): Awaitable<this> {
    $args = vec[
      'run',
      '--rm', // remove container when it exists
      '-d', // run the container in the background
      '-it',
      '--memory-reservation=150m',
      '--memory=180m',
      '--cpus=2',
      'hhvm/hhvm:'.$version,
    ];

    list($stdout, $_stderr) = await Process\execute('docker', $args);

    return new self(Str\trim($stdout));
  }

  /**
   * Create $filename inside the docker container, and write the given $content to it.
   */
  public async function write(
    string $filename,
    string $content,
  ): Awaitable<void> {
    using ($file = File\temporary_file()) {
      $handle = $file->getHandle();

      await $handle->writeAllAsync($content);

      await Process\execute('docker', vec[
        'cp',
        $handle->getPath(),
        Str\format('%s:%s', $this->container_id, $filename),
      ]);
    }
  }

  public async function getRuntimeVersion(): Awaitable<string> {
    list($_, $hhvm_version, $_) = await $this->execute(
      '/home',
      vec['hhvm', '--version'],
    );

    return $hhvm_version;
  }

  public async function getTypeCheckerVersion(): Awaitable<string> {
    list($_, $hh_client_version, $_) = await $this->execute(
      '/home',
      vec['hh_client', '--version'],
    );

    return $hh_client_version;
  }

  public async function getRuntimeResult(
    string $code,
    string $ini_configuration,
  ): Awaitable<(int, string, string)> {
    $file_awaitable = $this->write('/home/main.hack', $code);
    if ('' !== Str\trim($ini_configuration)) {
      concurrent {
        await $file_awaitable;
        await $this->write('/home/configuration.ini', $ini_configuration);
      }

      $args = vec['hhvm', '-c', 'configuration.ini', 'main.hack'];
    } else {
      $args = vec['hhvm', 'main.hack'];
    }

    $execution = await $this->execute('/home', $args, self::RUNTIME_TIMEOUT);

    return $execution;
  }

  public async function getTypeCheckerResult(
    string $code,
    string $hh_configuration,
  ): Awaitable<(int, string, string)> {
    concurrent {
      await $this->write('/home/main.hack', $code);
      await $this->write('/home/.hhconfig', $hh_configuration);

      await $this->execute('/home', vec['hh_server', '-d', '/home']);
    }

    return await $this->execute(
      '/home',
      vec['hh_client', '--error-format', 'highlighted'],
      self::TYPE_CHECKER_TIMEOUT,
    );
  }

  /**
   * Execute the given command inside the docker container.
   */
  private function execute(
    string $directory,
    vec<string> $arguments,
    ?int $ttl = null,
  ): Awaitable<(int, string, string)> {
    if ($ttl is nonnull) {
      $arguments = Vec\concat(
        vec[
          'timeout',
          Str\format('%ds', $ttl),
        ],
        $arguments,
      );
    }

    return static::sh('docker', Vec\concat(
      vec[
        'exec',
        '-w',
        $directory,
        $this->container_id,
      ],
      $arguments,
    ));
  }

  private static async function sh(
    string $command,
    vec<string> $arguments,
  ): Awaitable<(int, string, string)> {
    try {
      list($stdout, $stderr) = await Process\execute($command, $arguments);

      return tuple(0, $stdout, $stderr);
    } catch (Process\Exception\FailedExecutionException $e) {
      return tuple(
        $e->getExitCode(),
        $e->getStdoutContent(),
        $e->getStderrContent(),
      );
    }
  }

  public async function __disposeAsync(): Awaitable<void> {
    await static::sh('docker', vec[
      'kill',
      $this->container_id,
    ]);
  }
}
