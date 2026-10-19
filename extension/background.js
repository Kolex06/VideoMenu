const frames = new Map();
let port, enabled = true, updating = false, again = false;
let ready = chrome.storage.local.get({enabled:true}).then(s => { enabled = s.enabled; });
function badge(text, color) { chrome.action.setBadgeText({text}); chrome.action.setBadgeBackgroundColor({color}); }
function connect() {
  if (port) return port;
  try {
    const p = chrome.runtime.connectNative('local.videomenu.helper'); port = p;
    p.onMessage.addListener(m => badge(!enabled ? 'OFF' : m.hidden ? 'VID' : '', '#276749'));
    p.onDisconnect.addListener(() => { console.warn(chrome.runtime.lastError?.message || 'Helper disconnected'); if (port === p) port = undefined; badge('!', '#b91c1c'); });
    return p;
  } catch(e) { badge('!', '#b91c1c'); }
}
async function update() {
  await ready;
  if (updating) { again = true; return; }
  updating = true;
  try {
    const now = Date.now();
    for (const [k,v] of frames) if (now - v.time > 5500) frames.delete(k);
    const win = await chrome.windows.getLastFocused();
    const tabs = win.focused ? await chrome.tabs.query({active:true,windowId:win.id}) : [];
    const hide = enabled && tabs.some(t => [...frames.values()].some(v => v.tab === t.id && v.hide));
    connect()?.postMessage({enabled,hide});
  } catch(e) { console.warn(e); }
  finally { updating = false; if (again) { again = false; update(); } }
}
chrome.runtime.onMessage.addListener((m,sender) => {
  if (sender.id !== chrome.runtime.id || !sender.tab || !/^(https?:|about:)/.test(sender.url || '') || m?.type !== 'video-fullscreen' || typeof m.hide !== 'boolean') return;
  frames.set(`${sender.tab.id}:${sender.frameId}`, {tab:sender.tab.id,hide:m.hide,time:Date.now()}); update();
});
chrome.tabs.onActivated.addListener(update);
chrome.tabs.onRemoved.addListener(id => { for (const [k,v] of frames) if (v.tab === id) frames.delete(k); update(); });
chrome.tabs.onUpdated.addListener((id, change) => { if (change.status === 'loading') { for (const [k,v] of frames) if (v.tab === id) frames.delete(k); update(); } });
chrome.windows.onFocusChanged.addListener(update);
chrome.action.onClicked.addListener(async () => { await ready; enabled = !enabled; await chrome.storage.local.set({enabled}); update(); });
setInterval(update,1500);
update();
