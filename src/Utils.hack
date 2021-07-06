
namespace HHEvaluation;

use namespace HH;
use namespace HH\Lib\Str;

final abstract class Utils {
  public static function getCurrentDatetime(): \DateTimeImmutable {
    $dateTime = \DateTimeImmutable::createFromFormat(
      'U.u',
      Str\format('%.6F', \microtime(true)),
      new \DateTimeZone(\date_default_timezone_get()),
    ) as \DateTimeImmutable;

    $dateTime = $dateTime->setTimezone(new \DateTimeZone('GMT'))
      as \DateTimeImmutable;

    return $dateTime;
  }

  public static function getCurrentDatetimeString(): string {
    return self::getCurrentDatetime()->format('Y-m-d H:i:s');
  }

  public static function getDateTimeFromString(
    string $datetime,
  ): \DateTimeImmutable {
    return \DateTimeImmutable::createFromFormat(
      'Y-m-d H:i:s',
      $datetime,
      new \DateTimeZone('GMT'),
    ) as \DateTimeImmutable;
  }

  public static function getDueDaysFromString(string $datetime): int {
    $current_datetime = self::getCurrentDatetime();
    $past_datetime = self::getDateTimeFromString($datetime);

    $difference = $past_datetime->diff($current_datetime) as \DateInterval;

    return $difference->days;
  }
}
