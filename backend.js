const leadForm = document.querySelector('[data-lead-form]');

leadForm?.addEventListener('submit', async (event) => {
  event.preventDefault();
  const button = leadForm.querySelector('button');
  const status = leadForm.querySelector('[role="status"]');
  button.disabled = true;
  status.textContent = 'Enviando…';
  const values = Object.fromEntries(new FormData(leadForm));
  try {
    const response = await fetch('https://jogigyfekkahvbwmhpdh.functions.supabase.co/create-lead', {
      method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify(values),
    });
    const result = await response.json();
    if (!response.ok) throw new Error(result.error || 'Não foi possível enviar.');
    leadForm.reset(); status.textContent = 'Recebemos sua mensagem. Em breve entraremos em contato.';
  } catch (error) { status.textContent = error.message; }
  finally { button.disabled = false; }
});
