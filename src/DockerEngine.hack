namespace HHEvaluation;

use namespace HH\Lib\{IO, Str};
use namespace Nuxed\Http\{Client, Message};
use namespace Nuxed\Json;
use namespace Tarry;

/**
 * A wrapper around docker engine API for executing code samples.
 */
final class DockerEngine {
  private static ?Client\IHttpClient $client = null;

  /**
   * Run the give code sample in a Docker container.
   */
  public static async function run(
    Model\CodeSample $code,
    HHVM\Version $version,
  ): Awaitable<Model\CodeSampleResult::Structure> {
    $code_sample_data = $code->getData();

    $client = DockerEngine::getClient();
    $response = await $client->send(
      Message\Request\json(
        Message\uri('/containers/create'),
        dict[
          'Image' => Str\format('hhvm/hhvm:%s', $version),
          'WorkingDir' => '/home',
          'StopTimeout' => 120,
          'Tty' => true,
          'HostConfig' => dict[
            'Memory' => (1024 * 1024 * 180),
            'MemoryReservation' => (1024 * 1024 * 150),
            'AutoRemove' => true,
          ],
          'NetworkDisabled' => true,
        ],
      ),
    );

    invariant($response->getStatusCode() === 201, 'Failed to create container');

    $container_id = await $response->getBody()->readAllAsync()
      |> Json\typed<shape('Id' => string, ...)>($$)
      |> $$['Id'];

    await $client->request('POST', '/containers/'.$container_id.'/start');

    concurrent {
      await async {
        $response = await $client->send(
          Message\request(
            Message\HttpMethod::PUT,
            Message\uri('/containers/'.$container_id.'/archive?path=/home'),
            dict['Content-Type' => vec['application/x-tar']],
            Message\Body\memory(
              Tarry\ArchiveBuilder::create()
                ->withNode(shape(
                  'filename' => 'main.hack',
                  'content' => $code_sample_data['code'],
                ))
                ->withNode(shape(
                  'filename' => '.hhconfig',
                  'content' => $code_sample_data['hh_configuration'],
                ))
                ->withNode(shape(
                  'filename' => 'configuration.ini',
                  'content' => $code_sample_data['ini_configuration'],
                ))
                ->build(),
            ),
          ),
        );

        invariant(
          $response->getStatusCode() === 200,
          'Failed to put archive in the container.',
        );
      };

      list($_, $hhvm_version, $_) = await static::exec(
        $client,
        $container_id,
        vec['hhvm', '--version'],
      );
      list($_, $hh_version, $_) = await static::exec(
        $client,
        $container_id,
        vec['hh_client', '--version'],
      );
    }

    concurrent {
      list($hhvm_exit_code, $hhvm_stdout, $hhvm_stderr) = await static::exec(
        $client,
        $container_id,
        vec['hhvm', '-c', 'configuration.ini', 'main.hack'],
      );

      list($hh_exit_code, $hh_stdout, $hh_stderr) = await static::exec(
        $client,
        $container_id,
        vec['hh_client'],
      );
    }

    $response = await $client->request(
      'DELETE',
      '/containers/'.$container_id.'?v=true&force=true',
    );

    invariant($response->getStatusCode() === 204, 'Failed to remove container');

    return shape(
      'code_sample_id' => $code->getIdentifier(),
      'version' => $version,

      'runtime_detailed_version' => $hhvm_version,
      'runtime_exit_code' => $hhvm_exit_code,
      'runtime_stdout' => $hhvm_stdout,
      'runtime_stderr' => $hhvm_stderr,

      'type_checker_detailed_version' => $hh_version,
      'type_checker_exit_code' => $hh_exit_code,
      'type_checker_stdout' => $hh_stdout,
      'type_checker_stderr' => $hh_stderr,

      'last_updated' => Utils::getCurrentDatetimeString(),
    );
  }

  /**
   * Execute a command in the container.
   */
  private static async function exec(
    Client\IHttpClient $client,
    string $container_id,
    vec<string> $args,
  ): Awaitable<(int, string, string)> {
    $response = await $client->send(
      Message\Request\json(
        Message\uri('/containers/'.$container_id.'/exec'),
        dict[
          'AttachStdout' => true,
          'AttachStderr' => true,
          'Tty' => false,
          'Cmd' => $args,
          'NetworkDisabled' => true,
          'Detach' => false,
        ],
      ),
      shape(
        'debug' => true,
      ),
    );

    invariant($response->getStatusCode() === 201, 'Failed to create exec.');

    $exec_id = await $response->getBody()->readAllAsync()
      |> Json\typed<shape('Id' => string, ...)>($$)
      |> $$['Id'] as string;

    $response = await $client->send(
      Message\Request\json(
        Message\uri('/exec/'.$exec_id.'/start'),
        dict[
          'AttachStdout' => true,
          'AttachStderr' => true,
          'Tty' => false,
          'Cmd' => $args,
          'NetworkDisabled' => true,
          'Detach' => false,
        ],
      ),
      shape('debug' => true),
    );

    invariant($response->getStatusCode() === 200, 'Failed to start exec.');

    $output = await DockerEngine::split($response->getBody());

    do {
      $response = await $client->request('GET', '/exec/'.$exec_id.'/json');

      invariant($response->getStatusCode() === 200, 'Failed to get exec json.');

      $details = await $response->getBody()->readAllAsync()
        |> Json\typed<shape('ExitCode' => ?int, 'Running' => bool, ...)>($$);
    } while ($details['Running']);

    return tuple(
      $details['ExitCode'] as nonnull,
      $output['stdout'] as string,
      $output['stderr'] as string,
    );
  }

  /**
   * Create Http Client.
   */
  private static function getClient(): Client\IHttpClient {
    if (null !== static::$client) {
      return static::$client;
    }

    static::$client = Client\HttpClient::create(shape(
      'unix_socket' => '/var/run/docker.sock',
    ));

    return static::$client;
  }

  /**
   * Split docker raw stream into stdout and stderr.
   */
  private static async function split(
    IO\SeekableReadHandle $handle,
  ): Awaitable<shape('stdout' => string, 'stderr' => string)> {
    $reader = new IO\BufferedReader($handle);
    $stdout = '';
    $stderr = '';
    while (!$reader->isEndOfFile()) {
      $header = await $reader->readFixedSizeAsync(8);
      $decoded = \unpack('C1type/C3/N1size', $header) as dict<_, _>;
      $type = $decoded['type'] as int;
      $size = $decoded['size'] as int;

      $output = await $reader->readFixedSizeAsync($size);
      switch ($type) {
        case 1:
          $stdout .= $output;
          break;
        case 2:
          $stderr .= $output;
          break;
        default:
          invariant_violation('Stdin output encountered.');
          break;
      }
    }

    return shape('stdout' => $stdout, 'stderr' => $stderr);
  }
}
