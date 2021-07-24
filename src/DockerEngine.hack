namespace HHEvaluation;

use namespace HH\Lib\{C, IO, Str, Vec};
use namespace Nuxed\Http\{Client, Message};
use namespace Nuxed\{Environment, Json};
use namespace Tarry;

/**
 * A wrapper around docker engine API for executing code samples.
 */
final class DockerEngine {
  private static ?Client\IHttpClient $client = null;

  public static async function createAndStartContainer(
    HHVM\Version $version,
  ): Awaitable<string> {
    $client = DockerEngine::getClient();
    $response = await $client->send(
      Message\Request\json(
        Message\uri('/containers/create'),
        dict[
          'Image' => Str\format('hhvm/hhvm:%s', $version),
          'WorkingDir' => '/home',
          'StopTimeout' => 0,
          'Tty' => true,
          'HostConfig' => dict[
            'Memory' => (1024 * 1024 * 280),
            'MemoryReservation' => (1024 * 1024 * 250),
            'AutoRemove' => true,
          ],
          'NetworkDisabled' => true,
          'Labels' => dict[
            'org.nuxed.hhevaluation.container' => 'true',
            'org.nuxed.hhevaluation.version' => $version,
          ],
        ],
      ),
    );

    invariant($response->getStatusCode() === 201, 'Failed to create container');

    $container_id = await $response->getBody()->readAllAsync()
      |> Json\typed<shape('Id' => string, ...)>($$)
      |> $$['Id'];

    $response = await $client->request(
      'POST',
      '/containers/'.$container_id.'/start',
    );

    invariant($response->getStatusCode() === 204, 'Failed to start container');

    return $container_id;
  }

  public static async function findAllRunningContainers(
  ): Awaitable<vec<string>> {
    $client = DockerEngine::getClient();
    $response = await $client->request(
      Message\HttpMethod::GET,
      '/containers/json?filters={"label":["org.nuxed.hhevaluation.container"]}',
    );

    invariant($response->getStatusCode() === 200, 'Failed to get containers');

    return await $response->getBody()->readAllAsync()
      |> Json\typed<vec<shape('Id' => string, ...)>>($$)
      |> Vec\map($$, $container ==> $container['Id'] as string);
  }

  public static async function findOrCreateContainerForVersion(
    HHVM\Version $version,
  ): Awaitable<string> {
    $client = DockerEngine::getClient();
    $response = await $client->request(
      Message\HttpMethod::GET,
      '/containers/json?filters={"label":["org.nuxed.hhevaluation.container"]}',
    );

    invariant($response->getStatusCode() === 200, 'Failed to get containers');

    $container = await $response->getBody()->readAllAsync()
      |> Json\typed<
        vec<shape('Id' => string, 'Labels' => dict<string, string>, ...)>,
      >($$)
      |> Vec\filter(
        $$,
        ($container) ==> (
          $container['Labels']['org.nuxed.hhevaluation.version'] ?? null
        ) ===
          $version,
      )
      |> C\first($$);

    if (null === $container) {
      return await self::createAndStartContainer($version);
    }

    return $container['Id'];
  }

  public static async function forceDeleteContainer(
    string $container_id,
  ): Awaitable<void> {
    $client = self::getClient();
    $response = await $client->request(
      'DELETE',
      '/containers/'.$container_id.'?v=true&force=true',
    );

    invariant($response->getStatusCode() === 204, 'Failed to remove container');
  }

  /**
   * Extract an archive of code sample inside the given container.
   */
  public static async function archive(
    string $container_id,
    Model\CodeSample $code_sample,
  ): Awaitable<void> {
    $client = self::getClient();
    $code_sample_data = $code_sample->getData();

    $tar_handle = Tarry\ArchiveBuilder::create()
      ->withNode(shape(
        'filename' => Str\format('%d/main.hack', $code_sample->getIdentifier()),
        'content' => $code_sample_data['code'],
      ))
      ->withNode(shape(
        'filename' => Str\format('%d/.hhconfig', $code_sample->getIdentifier()),
        'content' => $code_sample_data['hh_configuration'],
      ))
      ->withNode(shape(
        'filename' =>
          Str\format('%d/configuration.ini', $code_sample->getIdentifier()),
        'content' => $code_sample_data['ini_configuration'],
      ))
      ->build()
      ->getHandle();

    $tar_handle->seek(0);
    $tar = await $tar_handle->readAllAsync();
    $response = await $client->send(
      Message\request(
        Message\HttpMethod::PUT,
        Message\uri('/containers/'.$container_id.'/archive?path=/home'),
        dict['Content-Type' => vec['application/x-tar']],
        Message\Body\memory($tar),
      ),
    );

    invariant(
      $response->getStatusCode() === 200,
      'Failed to put archive in the container.',
    );
  }

  /**
   * Execute a command in the container.
   */
  public static async function exec(
    string $container_id,
    vec<string> $args,
    string $working_dir,
    bool $needs_exit_code = true,
  ): Awaitable<(int, string, string)> {
    $client = self::getClient();
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
          'WorkingDir' => $working_dir,
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
          'WorkingDir' => $working_dir,
        ],
      ),
      shape(
        'debug' => true,
        'timeout' => 180.0,
        'connect_timeout' => 120.0,
      ),
    );

    invariant($response->getStatusCode() === 200, 'Failed to start exec.');

    $output = await DockerEngine::split($response->getBody());

    if ($needs_exit_code) {
      $response = await $client->request('GET', '/exec/'.$exec_id.'/json');

      invariant($response->getStatusCode() === 200, 'Failed to get exec json.');

      $details = await $response->getBody()->readAllAsync()
        |> Json\typed<shape('ExitCode' => int, 'Running' => bool, ...)>($$);

      // make sure that exec is complete
      invariant(
        $details['Running'] === false,
        'Exec is still running ( but we are not running in detach mode? ).',
      );

      $exit_code = $details['ExitCode'];
    } else {
      $exit_code = -1;
    }

    return tuple(
      $exit_code,
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

    // get the docker host socket from the environment.
    $unix_socket = Environment\get('DOCKER_HOST', '/var/run/docker.sock')
      as string;

    static::$client = Client\HttpClient::create(shape(
      'unix_socket' => $unix_socket,
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
      }
    }

    return shape('stdout' => $stdout, 'stderr' => $stderr);
  }
}
