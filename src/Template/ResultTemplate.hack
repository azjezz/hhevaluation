
namespace HHEvaluation\Template;

use namespace HH\Lib\Str;
use namespace HHEvaluation\ValueObject;
use type Facebook\XHP\HTML\{
  a,
  br,
  code,
  div,
  h2,
  hr,
  option,
  pre,
  select,
  span,
  textarea,
};

final class ResultTemplate {
  public static function render(
    ValueObject\EvaluationResult $result,
  ): Awaitable<string> {
    $selector =
      <select
        title="HHVM version"
        name="version"
        class=
          "form-input border border-gray-900 focus:border-gray-900 focus:ring-0 rounded-md w-full"
        disabled={true}
      />;

    $selector->appendChild(
      <option value={$result->version} selected={true}>
        {$result->version}
      </option>,
    );

    if ($result->hhvm_stdout !== '') {
      $hhvm_stdout =
        <pre class="text-base mb-2 code font-mono">
          <code>
            {$result->hhvm_stdout}
          </code>
        </pre>;
    } else {
      $hhvm_stdout = <div />;
    }

    $hh_client_stdout = Str\trim($result->hh_client_stdout, "\n");
    $hh_client_stdout =
      <pre
        class={
          $hh_client_stdout === 'No errors!'
            ? "text-base text-green-800 mb-2 code font-mono"
            : "text-base text-red-500 mb-2 code font-mono"
        }>
        <code>
          {$result->hh_client_stdout}
        </code>
      </pre>;

    return BaseTemplate::render(
      <div class="h-screen container w-full mx-auto px-10 py-8">
        <div class="w-full px-4 md:px-6 text-xl text-gray-800 leading-normal">
          <h2 class="text-xl">HHEvaluation <span
              class="text-gray-600 text-base">by <a
              class="underline"
              href="https://github.com/azjezz">azjezz</a>
            </span>
          </h2>
          <hr class="border border-red-500 mb-8 mt-4" />
          <div class="h-full grid grid-cols-2 gap-4">
            <div class="row-span-3  rounded-md text-gray-900">
              <textarea
                placeholder="Edit main.hack"
                id="code"
                rows={18}
                name="code"
                title="Hack code"
                class=
                  "px-4 py-3 form-input resize-none border border-gray-900 focus:border-gray-900 focus:ring-0 rounded-md w-full code font-mono"
                disabled={true}>
                {$result->code}
              </textarea>
              <textarea
                id="configuration"
                title=".hhconfig configuration"
                rows={8}
                name="configuration"
                class=
                  "px-4 py-3 mt-4 form-input resize-none border border-gray-900 focus:border-gray-900 focus:ring-0 rounded-md w-full code font-mono"
                disabled={true}>
                {$result->configuration}
              </textarea>
              <div class="mt-3">
                {$selector}
              </div>
            </div>
            <div
              class=
                "px-4 overflow-y-scroll  h-96 py-3 bg-white rounded-md text-gray-900 border border-gray-900 rounded-md w-full">
              {$hhvm_stdout}
              <pre class="text-gray-600 mb-4 text-sm code font-mono">
                <code>
                  {Str\trim_left($result->hhvm_stderr, "\n")}
                </code>
              </pre>
              <pre class="text-gray-500 text-xs code font-mono">
                <code>
                  {Str\trim_left($result->hhvm_version_output, "\n")}
                </code>
              </pre>
            </div>

            <div
              class=
                "px-4 py-3 overflow-y-scroll h-96 bg-white rounded-md text-gray-900 border border-gray-900 rounded-md w-full">
              {$hh_client_stdout}
              <pre class="text-gray-600 mb-4 text-sm code font-mono">
                <code>
                  {Str\trim_left($result->hh_client_stderr, "\n")}
                </code>
              </pre>
              <pre class="text-gray-500 text-xs code font-mono">
                <code>
                  {Str\trim_left($result->hh_client_version_output, "\n")}
                </code>
              </pre>
            </div>
          </div>
        </div>
      </div>,
    );
  }
}
