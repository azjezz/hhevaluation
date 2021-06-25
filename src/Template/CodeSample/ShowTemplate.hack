
namespace HHEvaluation\Template\CodeSample;

use namespace HHEvaluation\{HHVM, Model, Template};

use type Facebook\XHP\HTML\{code, div, option, pre, select, textarea};

final class ShowTemplate {
  public static function render(
    Model\CodeSample $code_sample,
    ?string $selected_version,
  ): Awaitable<string> {
    $versions = HHVM\Version::getValues();
    $selector =
      <select
        title="HHVM version"
        name="version"
        id="hhvm-version-selector"
        class=
          "form-input border border-gray-900 focus:border-gray-900 focus:ring-0 rounded-md w-full">
      </select>;
    foreach ($versions as $version) {
      if ((string)$version === $selected_version) {
        $selector->appendChild(
          <option value={$version} selected={true}>{$version}</option>,
        );
      } else {
        $selector->appendChild(<option value={$version}>{$version}</option>);
      }
    }

    $data = $code_sample->getData();

    return Template\BaseTemplate::render(
      <div
        class="h-full grid grid-cols-2 gap-4"
        id="main-container"
        data-identifier={$code_sample->getIdentifier()}>
        <div class="row-span-3  rounded-md text-gray-900">
          <textarea
            placeholder="main.hack"
            id="code"
            rows={18}
            name="code"
            title="Hack code"
            class=
              "px-4 py-3 form-input resize-none border border-gray-900 focus:border-gray-900 focus:ring-0 rounded-md w-full code font-mono"
            disabled={true}>
            {$data['code']}
          </textarea>

          <div class="grid grid-cols-2 gap-4">
            <div>
              <textarea
                placeholder=".hhconfig"
                id="hh_configuration"
                title=".hhconfig configuration"
                rows={8}
                name="hh_configuration"
                class=
                  "px-4 py-3 mt-4 form-input resize-none border border-gray-900 focus:border-gray-900 focus:ring-0 rounded-md w-full code font-mono"
                disabled={true}>
                {$data['hh_configuration']}
              </textarea>
            </div>
            <div>
              <textarea
                placeholder="configuration.ini"
                id="ini_configuration"
                rows={8}
                name="ini_configuration"
                class=
                  "px-4 py-3 mt-4 form-input resize-none border border-gray-900 focus:border-gray-900 focus:ring-0 rounded-md w-full code font-mono"
                disabled={true}>
                {$data['ini_configuration']}
              </textarea>
            </div>
          </div>

          <div class="mt-3">
            {$selector}
          </div>
        </div>
        <div
          class=
            "px-4 overflow-y-scroll  h-96 py-3 bg-white rounded-md text-gray-900 border border-gray-900 rounded-md w-full">
          <div class="animate-pulse flex space-x-4" id="runtime.animation">
            <div class="flex-1 space-y-4 py-1">
              <div class="h-4 bg-gray-400 rounded w-3/4"></div>
              <div class="space-y-2">
                <div class="h-4 bg-gray-400 rounded"></div>
                <div class="h-4 bg-gray-400 rounded w-5/6"></div>
              </div>
            </div>
          </div>

          <pre class="text-base mb-2 code font-mono hidden">
            <code id="runtime.stdout">Loading ...</code>
          </pre>

          <pre class="text-gray-600 mb-4 text-sm code font-mono hidden">
            <code id="runtime.stderr"></code>
          </pre>

          <pre class="text-gray-500 text-xs code font-mono hidden">
            <code id="runtime.version_details"></code>
          </pre>
        </div>

        <div
          class=
            "px-4 py-3 overflow-y-scroll h-96 bg-white rounded-md text-gray-900 border border-gray-900 rounded-md w-full">
          <div class="animate-pulse flex space-x-4" id="type-checker.animation">
            <div class="flex-1 space-y-4 py-1">
              <div class="h-4 bg-gray-400 rounded w-3/4"></div>
              <div class="space-y-2">
                <div class="h-4 bg-gray-400 rounded"></div>
                <div class="h-4 bg-gray-400 rounded w-5/6"></div>
              </div>
            </div>
          </div>

          <pre class="text-base text-red-500 mb-2 code font-mono hidden">
            <code id="type-checker.stdout">Loading ...</code>
          </pre>

          <pre class="text-gray-600 mb-4 text-sm code font-mono hidden">
            <code id="type-checker.stderr"></code>
          </pre>

          <pre class="text-gray-500 text-xs code font-mono hidden">
            <code id="type-checker.version_details"></code>
          </pre>
        </div>
      </div>,
    );
  }
}
