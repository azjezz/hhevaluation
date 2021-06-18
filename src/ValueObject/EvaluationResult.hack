
namespace HHEvaluation\ValueObject;

final class EvaluationResult {
  public function __construct(
    public string $identifier,

    public string $code,
    public string $configuration,
    public string $version,

    public string $hhvm_version_output,
    public int $hhvm_exit_code,
    public string $hhvm_stdout,
    public string $hhvm_stderr,

    public string $hh_client_version_output,
    public int $hh_client_exit_code,
    public string $hh_client_stdout,
    public string $hh_client_stderr,

    public \DateTimeImmutable $executed_at,
  )[] {}
}
