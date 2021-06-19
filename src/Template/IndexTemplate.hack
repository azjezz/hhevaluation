
namespace HHEvaluation\Template;

use namespace HHEvaluation\HHVM;
use type Facebook\XHP\HTML\{
  a,
  div,
  form,
  h2,
  hr,
  input,
  option,
  select,
  span,
  textarea,
};

final class IndexTemplate {
  const DEFAULT_CODE = <<<HACK
namespace Application;

use namespace HH\Lib\IO;

<<__EntryPoint>>
async function main(): Awaitable<void> {
  \$output = IO\\request_output();

  await \$output->writeAllAsync('Hello, World!');
}

HACK;

  const DEFAULT_CONFIG = <<<HACK
safe_array = true
safe_vector_array = true
unsafe_rx = false
const_default_func_args = true
disallow_array_literal = true
HACK;

  public static function render(): Awaitable<string> {
    $versions = HHVM\Version::getValues();
    $selector =
      <select
        title="HHVM version"
        name="version"
        class=
          "form-input border border-gray-900 focus:border-gray-900 focus:ring-0 rounded-md w-full">
      </select>;
    foreach ($versions as $version) {
      $selector->appendChild(<option value={$version}>{$version}</option>);
    }

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
          <div class="h-full row-span-3 rounded-md text-gray-900">
            <form action="/e" method="POST" spellcheck="false" id="hheForm">
              <textarea
                placeholder="Edit main.hack"
                id="code"
                rows={18}
                name="code"
                title="Hack code"
                class=
                  "px-4 py-3 form-input resize-none border border-gray-900 focus:border-gray-900 focus:ring-0 rounded-md w-full code font-mono">
                {self::DEFAULT_CODE}
              </textarea>

              <textarea
                id="configuration"
                title=".hhconfig configuration"
                rows={8}
                name="configuration"
                class=
                  "px-4 py-3 mt-4 form-input resize-none border border-gray-900 focus:border-gray-900 focus:ring-0 rounded-md w-full code font-mono">
                {self::DEFAULT_CONFIG}
              </textarea>

              <div class="grid grid-cols-2 gap-4 mt-3">
                <div>{$selector}</div>
                <div>
                  <input
                    type="submit"
                    value="Run"
                    id="hheRun"
                    class=
                      "bg-white hover:bg-gray-100 text-gray-800 py-1 border border-gray-900 rounded shadow float-right w-full"
                  />
                </div>
              </div>
            </form>
          </div>
        </div>
      </div>,
    );
  }
}
