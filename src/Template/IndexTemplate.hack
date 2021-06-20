
namespace HHEvaluation\Template;

use namespace HHEvaluation\HHVM;
use type Facebook\XHP\HTML\{
  a,
  div,
  form,
  h2,
  hr,
  button,
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
    return BaseTemplate::render(
      <div class="h-full row-span-3 rounded-md text-gray-900">
        <form action="/c" method="POST" spellcheck="false">
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

          <div class="grid grid-cols-2 gap-4">
            <div>
              <textarea
                placeholder="Edit .hhconfig"
                id="hh_configuration"
                title=".hhconfig configuration"
                rows={8}
                name="hh_configuration"
                class=
                  "px-4 py-3 mt-4 form-input resize-none border border-gray-900 focus:border-gray-900 focus:ring-0 rounded-md w-full code font-mono">
              </textarea>
            </div>
            <div>
              <textarea
                placeholder="Edit configuration.ini"
                id="ini_configuration"
                rows={8}
                name="ini_configuration"
                class=
                  "px-4 py-3 mt-4 form-input resize-none border border-gray-900 focus:border-gray-900 focus:ring-0 rounded-md w-full code font-mono">
              </textarea>
            </div>
          </div>
          <span class="relative inline-flex rounded-md shadow-sm w-full mt-4">
            <button
              type="submit"
              class=
                "w-full text-center py-1 border border-gray-900 font-medium rounded-md text-gray-800 bg-white hover:text-gray-700 focus:border-gray-800 transition ease-in-out duration-150">
              Run
            </button>
            <span class="flex absolute h-3 w-3 top-0 right-0 -mt-1 -mr-1">
              <span
                class=
                  "animate-ping absolute inline-flex h-full w-full rounded-full bg-purple-400 opacity-75">
              </span>
              <span
                class="relative inline-flex rounded-full h-3 w-3 bg-gray-500">
              </span>
            </span>
          </span>
        </form>
      </div>,
    );
  }
}
