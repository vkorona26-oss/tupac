// Small enough to stay readable: sticky nav state, release links, nothing else.

// Set when the repository is published: "owner/repo".
const REPO = '2p-executor/2p';
const VERSION = '3.2.0';

const nav = document.getElementById('nav');
const onScroll = () => nav.classList.toggle('solid', window.scrollY > 12);
onScroll();
window.addEventListener('scroll', onScroll, { passive: true });

function releaseUrl(file) {
  if (!REPO || REPO.startsWith('OWNER')) return '#download';
  return file
    ? `https://github.com/${REPO}/releases/latest/download/${file}`
    : `https://github.com/${REPO}/releases`;
}

const installer = document.getElementById('dl-installer');
const portable = document.getElementById('dl-portable');

if (installer) installer.href = releaseUrl(`2P-${VERSION}-Setup.exe`);
if (portable) portable.href = releaseUrl(`2P-${VERSION}-portable.zip`);

for (const link of document.querySelectorAll('[data-download]')) {
  if (link.id) continue;
  link.href = releaseUrl();
}

const note = document.getElementById('download-note');
if (note && REPO.startsWith('OWNER')) {
  note.textContent = 'Release artifacts are published on GitHub. Checksums ship with every release.';
}

// Anchors sit under a fixed 64px bar; offset them so headings stay visible.
for (const anchor of document.querySelectorAll('a[href^="#"]')) {
  anchor.addEventListener('click', (event) => {
    const id = anchor.getAttribute('href').slice(1);
    if (!id) return;
    const target = document.getElementById(id);
    if (!target) return;
    event.preventDefault();
    const top = target.getBoundingClientRect().top + window.scrollY - 80;
    window.scrollTo({ top, behavior: 'smooth' });
  });
}
