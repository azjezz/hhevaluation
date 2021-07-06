(function () {
  document.addEventListener('DOMContentLoaded', async () => {
    let tab = document.querySelectorAll('.tab')
    for (let i = 0; i < tab.length; i++) {
      tab[i].addEventListener('click', switch_tab, false)
    }

    if (document.location.pathname.startsWith('/c/')) {
      let hh_config = document.getElementById('hh_configuration').value
      let ini_config = document.getElementById('ini_configuration').value
      if ('' === hh_config.trim()) {
        let hh_tab_switch = document.getElementById('hh_configuration_tab_switch')
        hh_tab_switch.innerText = hh_tab_switch.innerText + ' (empty)'
        hh_tab_switch.classList.add('italic')
        hh_tab_switch.classList.remove('hover:text-gray-800')
        hh_tab_switch.disabled = true
      }

      if ('' === ini_config.trim()) {
        let ini_tab_switch = document.getElementById('ini_configuration_tab_switch')
        ini_tab_switch.innerText = ini_tab_switch.innerText + ' (empty)'
        ini_tab_switch.classList.add('italic')
        ini_tab_switch.classList.remove('hover:text-gray-800')
        ini_tab_switch.disabled = true
      }

      /** @type {String} selector */
      let identifier = document.getElementById('main-container').dataset.identifier
      /** @type {HTMLSelectElement} selector */
      let selector = document.getElementById('hhvm-version-selector')

      let version
      let promises = {}
      for (option of selector.options) {
        /**
         * @type {HTMLOptionElement} option
         */
        version = option.value

        promises[version] = get_result(identifier, version)
      }


      let update = async () => {
        selector.disabled = true

        hide_result()

        let url = new URL(window.location)
        url.searchParams.set('version', selector.value)
        window.history.pushState({}, '', url)

        await update_result(await promises[selector.value])

        selector.disabled = false
      }

      selector.addEventListener('change', update)

      await update()
    }
  })
})()

function hide_result() {
  document.getElementById('runtime.animation').classList.remove('hidden')
  document.getElementById('type_checker.animation').classList.remove('hidden')
  document.getElementById('runtime.stdout').parentElement.classList.add('hidden')
  document.getElementById('runtime.stderr').parentElement.classList.add('hidden')
  document.getElementById('runtime.version_details').parentElement.classList.add('hidden')
  document.getElementById('type_checker.stdout').parentElement.classList.add('hidden')
  document.getElementById('type_checker.stderr').parentElement.classList.add('hidden')
  document.getElementById('type_checker.version_details').parentElement.classList.add('hidden')

  document.getElementById('runtime_container').classList.add('border-gray-900')
  document.getElementById('runtime_container').classList.remove('border-red-500')

  document.getElementById('type_checker_container').classList.add('border-gray-900')
  document.getElementById('type_checker_container').classList.remove('border-red-500')
  document.getElementById('type_checker.stdout').parentElement.classList.remove('text-red-500')
}

async function update_result(result) {
  result = await result

  document.getElementById(`runtime.stdout`).innerText = result.runtime_stdout
  document.getElementById(`runtime.stderr`).innerText = result.runtime_stderr
  document.getElementById(`runtime.version_details`).innerText = result.runtime_detailed_version

  document.getElementById(`type_checker.stdout`).innerText = result.type_checker_stdout
  document.getElementById(`type_checker.stderr`).innerText = result.type_checker_stderr
  document.getElementById(`type_checker.version_details`).innerText = result.type_checker_detailed_version

  document.getElementById(`runtime.animation`).classList.add('hidden')
  document.getElementById(`type_checker.animation`).classList.add('hidden')

  // keep the element hidden if the content is empty.
  let empty_runtime_stdout = '' === result.runtime_stdout.trim()
  let empty_runtime_stderr = '' === result.runtime_stderr.trim()
  let empty_type_checker_stdout = '' === result.type_checker_stdout.trim()
  let empty_type_checker_stderr = '' === result.type_checker_stderr.trim()
  if (!empty_runtime_stdout) {
    document.getElementById(`runtime.stdout`).parentElement.classList.remove('hidden')
  }

  if (!empty_type_checker_stdout) {
    document.getElementById(`type_checker.stdout`).parentElement.classList.remove('hidden')
  }

  if (!empty_runtime_stderr) {
    document.getElementById(`runtime.stderr`).parentElement.classList.remove('hidden')
  }

  if (!empty_type_checker_stderr) {
    document.getElementById(`type_checker.stderr`).parentElement.classList.remove('hidden')
  }

  // hhvm exists with 255 if exit() hasn't been called.
  if (0 !== result.runtime_exit_code && 255 !== result.runtime_exit_code) {
    document.getElementById('runtime_container').classList.remove('border-gray-900')
    document.getElementById('runtime_container').classList.add('border-red-500')
  }

  if (0 !== result.type_checker_exit_code) {
    document.getElementById('type_checker_container').classList.remove('border-gray-900')
    document.getElementById('type_checker_container').classList.add('border-red-500')

    document.getElementById('type_checker.stdout').parentElement.classList.add('text-red-500')
  }

  document.getElementById('runtime.version_details').parentElement.classList.remove('hidden')
  document.getElementById('type_checker.version_details').parentElement.classList.remove('hidden')
}

async function get_result(identifier, version) {
  let response
  for (let i = 0; i < 3; i++) {
    response = await fetch('/c/' + identifier + '/result/' + version)
    if (response.status === 200) {
      return await response.json()
    }
  }

  throw new Error(`Failed to fetch HHVM ${version} results for ${identifier}`)
}


function switch_tab(event) {
  let tab = document.querySelectorAll('.tab')
  let panel = document.querySelectorAll('.tab-content')

  for (let i = 0; i < tab.length; i++) {
    tab[i].classList.remove('text-gray-800', 'border', 'border-b-0', 'border-gray-900', 'bg-white')
    tab[i].classList.add('text-gray-500')
  }

  for (let i = 0; i < panel.length; i++) {
    panel[i].classList.remove('active')
  }

  event.target.classList.add('text-gray-800', 'border', 'border-b-0', 'border-gray-800', 'bg-white')

  document.getElementById(
    event.target.getAttribute('data-target')
  ).classList.add("active")
}
