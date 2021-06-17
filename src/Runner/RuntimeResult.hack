namespace HHEvaluation\Runner;

final class RuntimeResult {
  public function __construct(public int $exit_code, public string $output)[] {}
}
