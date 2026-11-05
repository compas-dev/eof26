const mark = document.querySelector('#mark');
const motion = document.querySelector('#motion');
const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
let playing = !reducedMotion.matches;

function showMotion() {
  mark.src = playing ? 'assets/eof-wire.gif' : 'assets/eof-dark.png';
  motion.textContent = playing ? 'Pause motion' : 'Play motion';
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

form.addEventListener('submit', async (event) => {
  event.preventDefault();
  submit.disabled = true;
  try {
    const response = await fetch(form.action, { method: 'POST', body: new FormData(form) });
    const result = await response.json().catch(() => ({}));
    if (!response.ok || result.success === false) throw new Error('Subscription failed');
    form.reset();
    showStatus('Thank you for signing up! We are looking forward to seeing you.', false);
  } catch {
    showStatus('Something went wrong, please try again.', true);
  } finally {
    submit.disabled = false;
  }
});

showMotion();
