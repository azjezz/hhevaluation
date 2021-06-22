
namespace HHEvaluation\HHVM;

use namespace HH\Lib\{File, Str, Vec};
use namespace Nuxed\Process;

final class Container {
  private function __construct(private string $container_id) {}

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
   * Get Container by ID, or null if it does not exist.
   */
  public static async function get(string $id): Awaitable<?this> {
    list($_, $stdout, $_) = await self::sh('docker', vec[
      'ps',
      '--format',
      '"{{.ID}}"',
      '--filter',
      Str\format('id=%s', $id),
    ]);

    if (Str\trim($stdout) === '') {
      return null;
    }

    return new self($id);
  }

  /**
   * Create a new docker container for the given HHVM version.
   *
   * The container will be shutdown after $ttl seconds ( default to 360 ).
   */
  public static async function run(
    Version $version,
    int $ttl = 90,
  ): Awaitable<this> {
    list($stdout, $_stderr) = await Process\execute(
      'docker',
      vec[
        'run',
        '--rm', // remove container when it exists
        '-d', // run the container in the background
        '--memory-reservation=150m',
        '--memory=180m',
        '--cpus=2',
        'hhvm/hhvm:'.$version,
        'sleep',
        (string)$ttl,
      ],
    );

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

      return await $this->execute(
        '/home',
        vec['hhvm', '-c', 'configuration.ini', 'main.hack'],
      );
    }

    return await $this->execute('/home', vec['hhvm', 'main.hack']);
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

    return await $this->execute('/home', vec['hh_client', '--error-format', 'highlighted']);
  }

  /**
   * Execute the given command inside the docker container.
   */
  private function execute(
    string $directory,
    vec<string> $arguments,
  ): Awaitable<(int, string, string)> {
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
}
