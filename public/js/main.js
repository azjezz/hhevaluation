(function () {
  document.addEventListener('DOMContentLoaded', async () => {
    if (document.location.pathname.startsWith('/c/')) {
      /** @type {String} selector */
      let identifier = document.getElementById('main-container').dataset.identifier;
      /** @type {HTMLSelectElement} selector */
      let selector = document.getElementById('hhvm-version-selector');

      let version;
      let promises = {};
      for (option of selector.options) {
        /**
         * @type {HTMLOptionElement} option
         */
        version = option.value;

        promises[version] = {
          runtime: get_result('runtime', identifier, version),
          type_checker: get_result('type-checker', identifier, version),
        };
      }

      let update = async () => {
        selector.disabled = true;

        hide_result('type-checker')
        hide_result('runtime')

        let url = new URL(window.location);
        url.searchParams.set('version', selector.value);
        window.history.pushState({}, '', url);

        update_result('type-checker', await promises[selector.value]['type_checker'])
        update_result('runtime', await promises[selector.value]['runtime'])

        selector.disabled = false;
      };

      selector.addEventListener('change', update);

      await update();
    }
  });
})();

function hide_result(type) {
  document.getElementById(`${type}.animation`).classList.remove('hidden');

  document.getElementById(`${type}.stdout`).parentElement.classList.add('hidden');
  document.getElementById(`${type}.stderr`).parentElement.classList.add('hidden');
  document.getElementById(`${type}.version_details`).parentElement.classList.add('hidden');
}

function update_result(type, result) {
  document.getElementById(`${type}.stdout`).innerText = result.stdout_content;
  document.getElementById(`${type}.stderr`).innerText = result.stderr_content;
  document.getElementById(`${type}.version_details`).innerText = result.detailed_version;

  document.getElementById(`${type}.animation`).classList.add('hidden');

  // keep the element hidden if the content is empty.
  if ('' !== result.stdout_content.trim()) {
    document.getElementById(`${type}.stdout`).parentElement.classList.remove('hidden');
  }

  if ('' !== result.stderr_content.trim()) {
    document.getElementById(`${type}.stderr`).parentElement.classList.remove('hidden');
  }

  document.getElementById(`${type}.version_details`).parentElement.classList.remove('hidden');
}

async function get_result(type, identifier, version) {
  let response; for (let i = 0; i < 3; i++) {
    response = await fetch('/' + type + '/result/' + identifier + '/' + version)
    if (response.status === 200) {
      return response.json()
    }
  }

  throw new Error(`Failed to fetch HHVM ${version} ${type} results for ${identifier}`);
}
