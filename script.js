const menuButton = document.querySelector('.menu-toggle');
const navigation = document.querySelector('.topbar nav');
menuButton?.addEventListener('click', () => {
  const open = menuButton.getAttribute('aria-expanded') === 'true';
  menuButton.setAttribute('aria-expanded', String(!open));
  navigation.style.display = open ? '' : 'flex';
  if (!open) {
    navigation.style.cssText = 'display:flex;position:absolute;top:72px;left:6vw;right:6vw;flex-direction:column;gap:0;background:#081a31;padding:18px 20px;';
  } else navigation.removeAttribute('style');
});
document.querySelector('.finder')?.addEventListener('submit', (event) => {
  event.preventDefault();
  document.querySelector('#imoveis')?.scrollIntoView({ behavior: 'smooth' });
});
