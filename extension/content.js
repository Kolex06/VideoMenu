(() => {
  let timer;
  function send(hide) {
    try {
      if (!chrome.runtime.id) { clearInterval(timer); return; }
      chrome.runtime.sendMessage({type: 'video-fullscreen', hide}).catch(() => {});
    } catch { clearInterval(timer); }
  }
  function report() {
    const full = document.fullscreenElement || document.webkitFullscreenElement;
    const videos = full ? (full.matches('video') ? [full] : [...full.querySelectorAll('video')]) : [];
    const hide = videos.some(v => { const r = v.getBoundingClientRect(); return r.width > 32 && r.height > 32; });
    send(hide);
  }
  document.addEventListener('fullscreenchange', report);
  document.addEventListener('webkitfullscreenchange', report);
  window.addEventListener('pagehide', () => send(false));
  timer = setInterval(report, 1500);
  report();
})();
