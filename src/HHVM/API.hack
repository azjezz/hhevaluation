namespace HHEvaluation\HHVM;

use namespace HH\Lib\Str;
use namespace Nuxed\Http\{Client, Message};
use namespace Nuxed\Json;
use namespace HHEvaluation;

final class API {
  const NIGHTLY_STATUS = 'https://hhvm.com/api/build-status/nightly';

  public static async function getNightlyBuildDate(
  ): Awaitable<\DateTimeImmutable> {
    return await self::getBuildDate('nightly');
  }

  public static async function getBuildDate(
    string $version,
  ): Awaitable<\DateTimeImmutable> {
    $client = Client\HttpClient::create();
    $response = await $client
      ->request(
        Message\HttpMethod::GET,
        Str\format('https://hhvm.com/api/build-status/%s', $version),
      );

    $json = await $response->getBody()->readAllAsync();
    $result = Json\typed<shape(
      'success' => bool,
      'version' => string,
    )>($json);

    invariant(
      $result['success'],
      'Failed retriving %s build version.',
      $version,
    );

    return \DateTimeImmutable::createFromFormat('Y.m.d', $result['version']);
  }
}
