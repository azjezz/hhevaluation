
namespace HHEvaluation\Template;

use type Facebook\XHP\HTML\{
  code,
  pre,
  hr,
  button,
  div,
  form,
  span,
  textarea,
  nav,
  i,
};

final class IndexTemplate {
  const DEFAULT_CODE = <<<HACK
use namespace HH\Lib\IO;

<<__EntryPoint>>
async function main(): Awaitable<void> {
  await IO\\request_output()
    ->writeAllAsync('Hello, World!');

  exit(0);
}

HACK;

  public static function render(): Awaitable<string> {
    return BaseTemplate::render(
      <div class="h-full row-span-3 text-gray-900">
        <div class="-mb-px z-10 relative">
          <nav class="tabs flex flex-col sm:flex-row code text-base">
            <button
              data-target="code-panel"
              class=
                "tab py-2 px-4 block hover:text-gray-800 focus:outline-none text-gray-800 border border-b-0 border-gray-900 bg-white">
              main.hack
            </button>
            <button
              data-target="hh-panel"
              class=
                "tab py-2 px-4 block hover:text-gray-800 focus:outline-none text-gray-500">
              .hhconfig
            </button>
            <button
              data-target="ini-panel"
              class=
                "tab py-2 px-4 block hover:text-gray-800 focus:outline-none text-gray-500">
              configuration.ini
            </button>
          </nav>
        </div>

        <form action="/c" method="POST" spellcheck="false">
          <div id="panels" class="font-mono code text-base">
            <div id="code-panel" class="tab-content active">
              <textarea
                id="code"
                rows={12}
                name="code"
                class=
                  "px-4 py-3 form-input resize-none border border-gray-900 focus:border-gray-900 focus:ring-0 w-full overflow-y-scroll">
                {self::DEFAULT_CODE}
              </textarea>
            </div>
            <div id="hh-panel" class="tab-content">
              <textarea
                id="hh_configuration"
                rows={12}
                name="hh_configuration"
                class=
                  "px-4 py-3 form-input resize-none border border-gray-900 focus:border-gray-900 focus:ring-0 w-full overflow-y-scroll">
              </textarea>
            </div>
            <div id="ini-panel" class="tab-content">
              <textarea
                id="ini_configuration"
                rows={12}
                name="ini_configuration"
                class=
                  "px-4 py-3 form-input resize-none border border-gray-900 focus:border-gray-900 focus:ring-0 w-full overflow-y-scroll">
              </textarea>
            </div>
          </div>

          <button
            type="submit"
            class=
              "code text-base mt-3 w-full py-2 px-4 block hover:text-gray-800 focus:outline-none text-gray-800 border border-gray-900 bg-white">
            Run
          </button>
        </form>
      </div>,
    );
  }
}
