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

        promises[version] = (async (version) => {
          let runtime = await fetch_with_retry('/r/' + identifier + '/' + version).then((response) => response.json());
          let type_checker = await fetch_with_retry('/t/' + identifier + '/' + version).then((response) => response.json());

          return { runtime: runtime, type_checker: type_checker };
        })(version);
      }

      let update = async () => {
        selector.disabled = true;

        await update_results(selector.value, promises);

        let url = new URL(window.location);
        url.searchParams.set('version', selector.value);
        window.history.pushState({}, '', url);

        selector.disabled = false;
      };

      selector.addEventListener('change', update);


      await update();
    }
  });
})();

/**
 * @param {String} version
 * 
 * @return {Promise<void>}
 */
async function update_results(version, promises) {
  await Promise.all([
    update_runtime_result(version, promises),
    update_type_checker_result(version, promises)
  ]);
}

/**
 * @param {String} version
 * 
 * @return {Promise<void>}
 */
async function update_runtime_result(version, promises) {
  document.getElementById('runtime.animation').classList.remove('hidden');

  document.getElementById('runtime.stdout').parentElement.classList.add('hidden');
  document.getElementById('runtime.stderr').parentElement.classList.add('hidden');
  document.getElementById('runtime.version_details').parentElement.classList.add('hidden');

  let result = await promises[version];

  document.getElementById('runtime.stdout').innerText = result.runtime.stdout_content.trimStart();
  document.getElementById('runtime.stderr').innerText = result.runtime.stderr_content.trimStart();
  document.getElementById('runtime.version_details').innerText = result.runtime.detailed_version.trimStart();

  document.getElementById('runtime.animation').classList.add('hidden');

  // keep the element hidden if the content is empty.
  if ('' !== result.runtime.stdout_content.trim()) {
    document.getElementById('runtime.stdout').parentElement.classList.remove('hidden');
  }

  // keep the element hidden if the content is empty.
  if ('' !== result.runtime.stderr_content.trim()) {
    document.getElementById('runtime.stderr').parentElement.classList.remove('hidden');
  }

  document.getElementById('runtime.version_details').parentElement.classList.remove('hidden');
}

/**
 * @param {String} version
 * 
 * @return {Promise<void>}
 */
async function update_type_checker_result(version, promises) {
  document.getElementById('type_checker.animation').classList.remove('hidden');

  document.getElementById('type_checker.stdout').parentElement.classList.add('hidden');
  document.getElementById('type_checker.stderr').parentElement.classList.add('hidden');
  document.getElementById('type_checker.version_details').parentElement.classList.add('hidden');

  let result = await promises[version];

  document.getElementById('type_checker.stdout').innerText = result.type_checker.stdout_content.trimStart();
  document.getElementById('type_checker.stderr').innerText = result.type_checker.stderr_content.trimStart();
  document.getElementById('type_checker.version_details').innerText = result.type_checker.detailed_version.trimStart();

  document.getElementById('type_checker.animation').classList.add('hidden');

  // keep the element hidden if the content is empty.
  if ('' !== result.type_checker.stdout_content.trim()) {
    document.getElementById('type_checker.stdout').parentElement.classList.remove('hidden');
  }

  if ('' !== result.type_checker.stderr_content.trim()) {
    document.getElementById('type_checker.stderr').parentElement.classList.remove('hidden');
  }

  document.getElementById('type_checker.version_details').parentElement.classList.remove('hidden');
}

/**
 * @param {String} url
 * @param {Number} attempts
 * 
 * @returns {Promise<Response>}
 */
async function fetch_with_retry(url, attempts = 3) {
  let response;
  for (let i = 0; i < attempts; i++) {
    response = await fetch(url)
    if (response.status === 200) {
      return response
    }
  }

  throw new Error('Failed to fetch ' + url)
}
