(function () {
  document.addEventListener('DOMContentLoaded', async () => {
    if (document.location.pathname.startsWith('/c/')) {

      let update = async () => {
        /** @type {HTMLSelectElement} selector */
        let selector = document.getElementById('hhvm-version-selector');
        /** @type {String} selector */
        let identifier = document.getElementById('main-container').dataset.identifier;

        selector.disabled = true;
        await update_results(identifier, selector.value);

        let url = new URL(window.location);
        url.searchParams.set('version', selector.value);

        window.history.pushState({}, '', url);

        selector.disabled = false;
      };

      document.getElementById('hhvm-version-selector').addEventListener('change', update);

      await update();
    }
  });
})();

/**
 * @param {String} identifier
 * @param {String} version
 * 
 * @return {Promise<void>}
 */
async function update_results(identifier, version) {
  await Promise.all([
    update_runtime_result(identifier, version),
    update_type_checker_result(identifier, version)
  ]);
}

/**
 * @param {String} identifier
 * @param {String} version
 * 
 * @return {Promise<void>}
 */
async function update_runtime_result(identifier, version) {
  document.getElementById('runtime.animation').classList.remove('hidden');

  document.getElementById('runtime.stdout').parentElement.classList.add('hidden');
  document.getElementById('runtime.stderr').parentElement.classList.add('hidden');
  document.getElementById('runtime.version_details').parentElement.classList.add('hidden');

  let response = await fetch('/r/' + identifier + '/' + version);

  let result = await response.json();

  document.getElementById('runtime.stdout').innerText = result.stdout_content.trimStart();
  document.getElementById('runtime.stderr').innerText = result.stderr_content.trimStart();
  document.getElementById('runtime.version_details').innerText = result.detailed_version.trimStart();

  document.getElementById('runtime.animation').classList.add('hidden');

  // keep the element hidden if the content is empty.
  if ('' !== result.stdout_content.trim()) {
    document.getElementById('runtime.stdout').parentElement.classList.remove('hidden');
  }

  // keep the element hidden if the content is empty.
  if ('' !== result.stderr_content.trim()) {
    document.getElementById('runtime.stderr').parentElement.classList.remove('hidden');
  }

  document.getElementById('runtime.version_details').parentElement.classList.remove('hidden');
}

/**
 * @param {String} identifier
 * @param {String} version
 * 
 * @return {Promise<void>}
 */
async function update_type_checker_result(identifier, version) {
  document.getElementById('type_checker.animation').classList.remove('hidden');

  document.getElementById('type_checker.stdout').parentElement.classList.add('hidden');
  document.getElementById('type_checker.stderr').parentElement.classList.add('hidden');
  document.getElementById('type_checker.version_details').parentElement.classList.add('hidden');

  let response = await fetch('/t/' + identifier + '/' + version);

  let result = await response.json();

  document.getElementById('type_checker.stdout').innerText = result.stdout_content.trimStart();
  document.getElementById('type_checker.stderr').innerText = result.stderr_content.trimStart();
  document.getElementById('type_checker.version_details').innerText = result.detailed_version.trimStart();

  document.getElementById('type_checker.animation').classList.add('hidden');


  // keep the element hidden if the content is empty.
  if ('' !== result.stdout_content.trim()) {
    document.getElementById('type_checker.stdout').parentElement.classList.remove('hidden');
  }

  if ('' !== result.stderr_content.trim()) {
    document.getElementById('type_checker.stderr').parentElement.classList.remove('hidden');
  }

  document.getElementById('type_checker.version_details').parentElement.classList.remove('hidden');
}
