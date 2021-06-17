namespace HHEvaluation\Runner;

final class Script {
  public function __construct(
    public string $code,
    public HHVMVersion $version,
  )[] {}
}
