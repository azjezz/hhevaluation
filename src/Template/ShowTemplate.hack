
namespace HHEvaluation\Template;

use namespace HHEvaluation\{HHVM, Model, Template};

use type Facebook\XHP\HTML\{
  button,
  code,
  div,
  hr,
  nav,
  option,
  pre,
  select,
  textarea,
};

final class ShowTemplate {
  public static function rendexr(
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
            "px-4 overflow-y-scroll  h-96 py-3 bg-white rounded-md text-gray-900 border border-gray-900 rounded-md w-full"
          id="runtime_container">
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
            "px-4 py-3 overflow-y-scroll h-96 bg-white rounded-md text-gray-900 border border-gray-900 rounded-md w-full"
          id="type_checker_container">
          <div class="animate-pulse flex space-x-4" id="type_checker.animation">
            <div class="flex-1 space-y-4 py-1">
              <div class="h-4 bg-gray-400 rounded w-3/4"></div>
              <div class="space-y-2">
                <div class="h-4 bg-gray-400 rounded"></div>
                <div class="h-4 bg-gray-400 rounded w-5/6"></div>
              </div>
            </div>
          </div>

          <pre class="text-base text-red-500 mb-2 code font-mono hidden">
            <code id="type_checker.stdout">Loading ...</code>
          </pre>

          <pre class="text-gray-600 mb-4 text-sm code font-mono hidden">
            <code id="type_checker.stderr"></code>
          </pre>

          <pre class="text-gray-500 text-xs code font-mono hidden">
            <code id="type_checker.version_details"></code>
          </pre>
        </div>
      </div>,
    );
  }

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
          "code text-base mt-3 form-input border border-gray-900 focus:border-gray-900 focus:ring-0 w-full">
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
        class="h-full row-span-3 text-gray-900"
        id="main-container"
        data-identifier={$code_sample->getIdentifier()}>
        <div class="-mb-px z-10 relative">
          <nav class="tabs flex flex-col sm:flex-row code text-base">
            <button
              data-target="code-panel"
              id="code_tab_switch"
              class=
                "tab py-2 px-4 block hover:text-gray-800 focus:outline-none text-gray-800 border border-b-0 border-gray-900 bg-white">
              main.hack
            </button>
            <button
              data-target="hh-panel"
              id="hh_configuration_tab_switch"
              class=
                "tab py-2 px-4 block hover:text-gray-800 focus:outline-none text-gray-500">
              .hhconfig
            </button>
            <button
              data-target="ini-panel"
              id="ini_configuration_tab_switch"
              class=
                "tab py-2 px-4 block hover:text-gray-800 focus:outline-none text-gray-500">
              configuration.ini
            </button>
          </nav>
        </div>

        <div>
          <div id="panels" class="font-mono code text-base">
            <div id="code-panel" class="tab-content active">
              <textarea
                id="code"
                rows={12}
                name="code"
                class=
                  "px-4 py-3 form-input resize-none border border-gray-900 focus:border-gray-900 focus:ring-0 w-full overflow-y-scroll"
                readonly={true}>
                {$data['code']}
              </textarea>
            </div>
            <div id="hh-panel" class="tab-content">
              <textarea
                id="hh_configuration"
                rows={12}
                name="hh_configuration"
                class=
                  "px-4 py-3 form-input resize-none border border-gray-900 focus:border-gray-900 focus:ring-0 w-full overflow-y-scroll"
                readonly={true}>
                {$data['hh_configuration']}
              </textarea>
            </div>
            <div id="ini-panel" class="tab-content">
              <textarea
                id="ini_configuration"
                rows={12}
                name="ini_configuration"
                class=
                  "px-4 py-3 form-input resize-none border border-gray-900 focus:border-gray-900 focus:ring-0 w-full overflow-y-scroll"
                readonly={true}>
                {$data['ini_configuration']}
              </textarea>
            </div>
          </div>

          {$selector}
        </div>

        <hr class="border border-gray-300 my-4" />

        <div class="grid grid-cols-2 gap-4 mb-2 code font-mono text-base">
          <div>
            <div
              class=
                "px-4 overflow-y-scroll h-72 py-3 bg-white text-gray-900 border border-gray-900 w-full"
              id="runtime_container">
              <div class="animate-pulse flex space-x-4" id="runtime.animation">
                <div class="flex-1 space-y-4 py-1">
                  <div class="h-4 bg-gray-400 rounded w-3/4"></div>
                  <div class="space-y-2">
                    <div class="h-4 bg-gray-400 rounded"></div>
                    <div class="h-4 bg-gray-400 rounded w-5/6"></div>
                  </div>
                </div>
              </div>

              <pre class="mb-2 hidden">
                <code id="runtime.stdout"></code>
              </pre>

              <pre class="text-gray-600 mb-4 text-sm hidden">
                <code id="runtime.stderr"></code>
              </pre>

              <pre class="text-gray-500 text-xs hidden">
                <code id="runtime.version_details"></code>
              </pre>
            </div>
          </div>
          <div>
            <div
              class=
                "px-4 py-3 overflow-y-scroll h-72 bg-white text-gray-900 border border-gray-900 w-full"
              id="type_checker_container">
              <div
                class="animate-pulse flex space-x-4"
                id="type_checker.animation">
                <div class="flex-1 space-y-4 py-1">
                  <div class="h-4 bg-gray-400 rounded w-3/4"></div>
                  <div class="space-y-2">
                    <div class="h-4 bg-gray-400 rounded"></div>
                    <div class="h-4 bg-gray-400 rounded w-5/6"></div>
                  </div>
                </div>
              </div>

              <pre class="text-red-500 mb-2 hidden">
                <code id="type_checker.stdout"></code>
              </pre>

              <pre class="text-gray-600 mb-4 text-sm hidden">
                <code id="type_checker.stderr"></code>
              </pre>

              <pre class="text-gray-500 text-xs hidden">
                <code id="type_checker.version_details"></code>
              </pre>
            </div>
          </div>
        </div>
      </div>,
    );
  }
}
