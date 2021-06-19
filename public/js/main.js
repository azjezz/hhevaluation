(function () {
  document.addEventListener('DOMContentLoaded', () => {

    let form = document.getElementById('hheForm');

    if (form) {
      form.addEventListener('submit', () => {
        // prevent the user submitting the form twice on a row
        let button = document.getElementById('hheRun')
        button.disabled = true;
        button.value = 'Running...'
      })
    }
  })
})();