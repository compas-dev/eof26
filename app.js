const mark = document.querySelector('#mark');
const motion = document.querySelector('#motion');
const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
let playing = !reducedMotion.matches;

function showMotion() {
  mark.src = playing ? 'assets/eof-wire.gif' : 'assets/eof-dark.png';
  motion.dataset.playing = String(playing);
  motion.setAttribute('aria-label', playing ? 'Pause motion' : 'Play motion');
}

motion.addEventListener('click', () => {
  playing = !playing;
  showMotion();
});

reducedMotion.addEventListener('change', (event) => {
  playing = !event.matches;
  showMotion();
});

const form = document.querySelector('#rsvp-form');
const status = document.querySelector('#form-status');

const submit = form.querySelector('button[type="submit"]');

function showStatus(message, isError) {
  status.hidden = false;
  status.textContent = message;
  status.classList.toggle('error', isError);
}

const done = document.querySelector('#rsvp-done');

function showDone(email) {
  status.hidden = true;
  document.querySelector('#rsvp-email').textContent = email;
  form.dataset.sent = '';
  done.hidden = false;
  done.focus({ preventScroll: true });
  done.scrollIntoView({ behavior: reducedMotion.matches ? 'auto' : 'smooth', block: 'center' });
}

document.querySelector('#rsvp-again').addEventListener('click', () => {
  delete form.dataset.sent;
  done.hidden = true;
  form.querySelector('input[name="fields[name]"]').focus();
});

form.addEventListener('submit', async (event) => {
  event.preventDefault();
  submit.disabled = true;
  try {
    const response = await fetch(form.action, { method: 'POST', body: new FormData(form) });
    const result = await response.json().catch(() => ({}));
    if (!response.ok || result.success === false) throw new Error('Subscription failed');
    showDone(form.elements['fields[email]'].value);
    form.reset();
  } catch {
    showStatus('Something went wrong, please try again.', true);
  } finally {
    submit.disabled = false;
  }
});

showMotion();
