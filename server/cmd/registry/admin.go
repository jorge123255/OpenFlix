package main

// adminHTML is the self-contained admin UI served at GET /admin.
// It uses fetch() to call the JSON API endpoints and stores the bearer
// token in sessionStorage so the user only has to type it once per tab.
const adminHTML = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>OpenFlix — License Admin</title>
<style>
  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

  :root {
    --bg:        #0e0f13;
    --surface:   #16181f;
    --surface2:  #1e2028;
    --border:    #2a2d38;
    --accent:    #3b82f6;
    --accent-h:  #2563eb;
    --danger:    #ef4444;
    --danger-h:  #dc2626;
    --warn:      #f59e0b;
    --green:     #22c55e;
    --text:      #e2e4ed;
    --muted:     #6b7280;
    --mono:      'SF Mono', 'Fira Code', 'Fira Mono', Menlo, monospace;
    --sans:      -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    --radius:    6px;
  }

  body {
    background: var(--bg);
    color: var(--text);
    font-family: var(--sans);
    font-size: 14px;
    line-height: 1.5;
    min-height: 100vh;
  }

  /* ── Login screen ── */
  #login-screen {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    min-height: 100vh;
    gap: 16px;
  }
  #login-screen h1 { font-size: 22px; font-weight: 700; color: var(--text); }
  #login-screen p  { color: var(--muted); font-size: 13px; }
  .login-card {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: 10px;
    padding: 32px 28px;
    width: 360px;
    display: flex;
    flex-direction: column;
    gap: 14px;
  }
  .login-card label { font-size: 12px; color: var(--muted); text-transform: uppercase; letter-spacing: .05em; }
  .login-card input[type="password"] {
    width: 100%;
    padding: 10px 12px;
    background: var(--bg);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    color: var(--text);
    font-family: var(--mono);
    font-size: 14px;
    outline: none;
    transition: border-color .15s;
  }
  .login-card input[type="password"]:focus { border-color: var(--accent); }
  #login-error { color: var(--danger); font-size: 13px; display: none; }

  /* ── Main app (hidden until authenticated) ── */
  #app { display: none; flex-direction: column; min-height: 100vh; }

  /* ── Top bar ── */
  header {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 14px 24px;
    border-bottom: 1px solid var(--border);
    background: var(--surface);
    position: sticky; top: 0; z-index: 10;
  }
  header .logo { font-size: 18px; font-weight: 800; color: var(--text); letter-spacing: -.02em; }
  header .logo span { color: var(--accent); }
  header .subtitle { color: var(--muted); font-size: 12px; }
  header .spacer { flex: 1; }
  header button.logout {
    background: transparent;
    border: 1px solid var(--border);
    color: var(--muted);
    padding: 5px 12px;
    border-radius: var(--radius);
    cursor: pointer;
    font-size: 12px;
    transition: border-color .15s, color .15s;
  }
  header button.logout:hover { border-color: var(--text); color: var(--text); }

  /* ── Main layout ── */
  main { display: flex; flex-direction: column; gap: 20px; padding: 24px; max-width: 1300px; width: 100%; margin: 0 auto; }

  /* ── Stats bar ── */
  .stats { display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; }
  .stat-card {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    padding: 16px 20px;
    display: flex;
    flex-direction: column;
    gap: 4px;
  }
  .stat-card .label { font-size: 11px; text-transform: uppercase; letter-spacing: .06em; color: var(--muted); }
  .stat-card .value { font-size: 28px; font-weight: 700; line-height: 1; }
  .stat-card.total  .value { color: var(--text); }
  .stat-card.active .value { color: var(--green); }
  .stat-card.expired .value { color: var(--warn); }
  .stat-card.revoked .value { color: var(--danger); }

  /* ── Two-column panel ── */
  .panels { display: grid; grid-template-columns: 1fr 340px; gap: 16px; align-items: start; }
  @media (max-width: 900px) { .panels { grid-template-columns: 1fr; } }

  /* ── Card ── */
  .card {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    overflow: hidden;
  }
  .card-header {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 14px 16px;
    border-bottom: 1px solid var(--border);
  }
  .card-header h2 { font-size: 14px; font-weight: 600; flex: 1; }

  /* ── Search bar ── */
  .search-wrap { position: relative; flex: 1; }
  .search-wrap input {
    width: 100%;
    padding: 6px 10px 6px 32px;
    background: var(--bg);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    color: var(--text);
    font-size: 13px;
    outline: none;
    transition: border-color .15s;
  }
  .search-wrap input:focus { border-color: var(--accent); }
  .search-wrap svg { position: absolute; left: 8px; top: 50%; transform: translateY(-50%); color: var(--muted); pointer-events: none; }

  /* ── Table ── */
  .table-wrap { overflow-x: auto; }
  table { width: 100%; border-collapse: collapse; }
  th {
    text-align: left;
    font-size: 11px;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: .06em;
    color: var(--muted);
    padding: 10px 14px;
    border-bottom: 1px solid var(--border);
    white-space: nowrap;
  }
  td { padding: 10px 14px; border-bottom: 1px solid var(--border); vertical-align: middle; }
  tr:last-child td { border-bottom: none; }
  tr:hover td { background: var(--surface2); }

  .key-cell { font-family: var(--mono); font-size: 12px; color: var(--muted); white-space: nowrap; }
  .email-cell { max-width: 200px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }

  /* ── Status badge ── */
  .badge {
    display: inline-block;
    font-size: 11px;
    font-weight: 600;
    padding: 2px 8px;
    border-radius: 999px;
    text-transform: uppercase;
    letter-spacing: .05em;
  }
  .badge.active  { background: rgba(34,197,94,.15);  color: var(--green); }
  .badge.expired { background: rgba(245,158,11,.15); color: var(--warn); }
  .badge.revoked { background: rgba(239,68,68,.15);  color: var(--danger); }

  /* ── Action buttons in table ── */
  .action-group { display: flex; gap: 6px; align-items: center; }
  .btn-icon {
    background: transparent;
    border: 1px solid var(--border);
    border-radius: var(--radius);
    color: var(--muted);
    padding: 4px 8px;
    cursor: pointer;
    font-size: 11px;
    white-space: nowrap;
    transition: all .15s;
  }
  .btn-icon:hover { border-color: var(--text); color: var(--text); }
  .btn-icon.danger:hover { border-color: var(--danger); color: var(--danger); }
  .btn-icon:disabled { opacity: .4; cursor: not-allowed; }

  /* ── Inline date picker for extend ── */
  .extend-row { display: flex; gap: 6px; align-items: center; }
  .extend-row input[type="date"] {
    background: var(--bg);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    color: var(--text);
    padding: 3px 7px;
    font-size: 12px;
    outline: none;
    color-scheme: dark;
  }
  .extend-row input[type="date"]:focus { border-color: var(--accent); }

  /* ── Create form ── */
  .form-body { padding: 16px; display: flex; flex-direction: column; gap: 14px; }
  .field { display: flex; flex-direction: column; gap: 5px; }
  .field label { font-size: 11px; text-transform: uppercase; letter-spacing: .05em; color: var(--muted); }
  .field input {
    padding: 8px 10px;
    background: var(--bg);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    color: var(--text);
    font-size: 13px;
    outline: none;
    transition: border-color .15s;
  }
  .field input[type="date"] { color-scheme: dark; }
  .field input:focus { border-color: var(--accent); }
  .field .hint { font-size: 11px; color: var(--muted); }

  /* ── Buttons ── */
  .btn {
    padding: 9px 16px;
    border: none;
    border-radius: var(--radius);
    font-size: 13px;
    font-weight: 600;
    cursor: pointer;
    transition: background .15s, opacity .15s;
  }
  .btn:disabled { opacity: .5; cursor: not-allowed; }
  .btn.primary { background: var(--accent); color: #fff; }
  .btn.primary:hover:not(:disabled) { background: var(--accent-h); }
  .btn.danger  { background: var(--danger); color: #fff; }
  .btn.danger:hover:not(:disabled)  { background: var(--danger-h); }

  /* ── Generated key box ── */
  .key-result {
    display: none;
    flex-direction: column;
    gap: 8px;
    background: var(--bg);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    padding: 12px;
  }
  .key-result .key-label { font-size: 11px; color: var(--muted); text-transform: uppercase; letter-spacing: .05em; }
  .key-result .key-value {
    font-family: var(--mono);
    font-size: 13px;
    word-break: break-all;
    color: var(--green);
  }
  .key-result .copy-hint { font-size: 11px; color: var(--muted); }

  /* ── Empty / loading states ── */
  .empty-state { padding: 40px; text-align: center; color: var(--muted); font-size: 13px; }
  .spinner {
    display: inline-block;
    width: 16px; height: 16px;
    border: 2px solid var(--border);
    border-top-color: var(--accent);
    border-radius: 50%;
    animation: spin .6s linear infinite;
    vertical-align: middle;
  }
  @keyframes spin { to { transform: rotate(360deg); } }

  /* ── Toast ── */
  #toast {
    position: fixed;
    bottom: 24px; right: 24px;
    background: var(--surface2);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    padding: 10px 16px;
    font-size: 13px;
    color: var(--text);
    opacity: 0;
    transform: translateY(8px);
    transition: opacity .2s, transform .2s;
    pointer-events: none;
    z-index: 100;
    max-width: 320px;
  }
  #toast.show { opacity: 1; transform: translateY(0); }
  #toast.success { border-color: var(--green); color: var(--green); }
  #toast.error   { border-color: var(--danger); color: var(--danger); }
</style>
</head>
<body>

<!-- ══ Login screen ══════════════════════════════════════════════════════════ -->
<div id="login-screen">
  <div class="login-card">
    <h1 style="text-align:center">OpenFlix <span style="color:var(--accent)">Admin</span></h1>
    <p style="text-align:center;color:var(--muted);font-size:13px">License Management Console</p>
    <div class="field">
      <label>Admin Secret</label>
      <input type="password" id="secret-input" placeholder="Enter ADMIN_SECRET…" autocomplete="current-password">
    </div>
    <span id="login-error">Invalid secret — please try again.</span>
    <button class="btn primary" id="login-btn">Sign In</button>
  </div>
</div>

<!-- ══ Main app ══════════════════════════════════════════════════════════════ -->
<div id="app">
  <header>
    <span class="logo">Open<span>Flix</span></span>
    <span class="subtitle">License Admin</span>
    <span class="spacer"></span>
    <button class="logout" id="logout-btn">Sign out</button>
  </header>

  <main>
    <!-- Stats bar -->
    <div class="stats">
      <div class="stat-card total">
        <span class="label">Total</span>
        <span class="value" id="stat-total">—</span>
      </div>
      <div class="stat-card active">
        <span class="label">Active</span>
        <span class="value" id="stat-active">—</span>
      </div>
      <div class="stat-card expired">
        <span class="label">Expired</span>
        <span class="value" id="stat-expired">—</span>
      </div>
      <div class="stat-card revoked">
        <span class="label">Revoked</span>
        <span class="value" id="stat-revoked">—</span>
      </div>
    </div>

    <!-- Panels -->
    <div class="panels">

      <!-- Left: license table -->
      <div class="card">
        <div class="card-header">
          <h2>Licenses</h2>
          <div class="search-wrap">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/></svg>
            <input type="text" id="search-input" placeholder="Filter by email or key…">
          </div>
          <button class="btn-icon" id="refresh-btn" title="Refresh">↻ Refresh</button>
        </div>
        <div class="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Key</th>
                <th>Email</th>
                <th>Created</th>
                <th>Expires</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody id="license-tbody">
              <tr><td colspan="6" class="empty-state"><span class="spinner"></span> Loading…</td></tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Right: create form -->
      <div class="card">
        <div class="card-header">
          <h2>Create License</h2>
        </div>
        <div class="form-body">
          <div class="field">
            <label>Email address</label>
            <input type="email" id="create-email" placeholder="customer@example.com">
          </div>
          <div class="field">
            <label>Expiration date <span style="color:var(--muted);text-transform:none;font-size:11px">(optional)</span></label>
            <input type="date" id="create-expires">
            <span class="hint">Leave blank for no expiration.</span>
          </div>
          <button class="btn primary" id="create-btn">Generate Key</button>

          <!-- Generated key result -->
          <div class="key-result" id="key-result">
            <span class="key-label">Generated Key</span>
            <span class="key-value" id="key-value"></span>
            <button class="btn-icon" id="copy-btn" style="align-self:flex-start">⎘ Copy key</button>
            <span class="copy-hint">Share this key with the customer. It cannot be retrieved again.</span>
          </div>
        </div>
      </div>

    </div><!-- /panels -->
  </main>
</div>

<div id="toast"></div>

<script>
'use strict';

// ── State ─────────────────────────────────────────────────────────────────
let token = sessionStorage.getItem('of_admin_token') || '';
let allLicenses = [];

// ── Helpers ───────────────────────────────────────────────────────────────
function toast(msg, type = '') {
  const el = document.getElementById('toast');
  el.textContent = msg;
  el.className = 'show ' + type;
  clearTimeout(el._t);
  el._t = setTimeout(() => { el.className = ''; }, 3200);
}

function formatDate(isoStr) {
  if (!isoStr) return '—';
  const d = new Date(isoStr);
  return d.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });
}

function licenseStatus(lic) {
  if (!lic.active) return 'revoked';
  if (lic.expiresAt && new Date(lic.expiresAt) < new Date()) return 'expired';
  return 'active';
}

function truncateKey(key) {
  if (key.length <= 16) return key;
  return key.slice(0, 8) + '…' + key.slice(-4);
}

async function apiFetch(path, opts = {}) {
  const res = await fetch(path, {
    ...opts,
    headers: {
      'Authorization': 'Bearer ' + token,
      'Content-Type': 'application/json',
      ...(opts.headers || {}),
    },
  });
  return res;
}

// ── Auth ──────────────────────────────────────────────────────────────────
function showApp() {
  document.getElementById('login-screen').style.display = 'none';
  const app = document.getElementById('app');
  app.style.display = 'flex';
  loadLicenses();
}

function showLogin(error) {
  document.getElementById('app').style.display = 'none';
  document.getElementById('login-screen').style.display = 'flex';
  if (error) {
    const el = document.getElementById('login-error');
    el.style.display = 'block';
    el.textContent = error;
  }
}

async function tryLogin() {
  const input = document.getElementById('secret-input');
  const candidate = input.value.trim();
  if (!candidate) return;

  const btn = document.getElementById('login-btn');
  btn.disabled = true;
  btn.textContent = 'Checking…';

  // Probe the API with this token
  token = candidate;
  const res = await apiFetch('/admin/licenses').catch(() => null);
  btn.disabled = false;
  btn.textContent = 'Sign In';

  if (res && res.ok) {
    sessionStorage.setItem('of_admin_token', token);
    document.getElementById('login-error').style.display = 'none';
    input.value = '';
    showApp();
  } else {
    token = '';
    sessionStorage.removeItem('of_admin_token');
    showLogin('Invalid secret — please try again.');
  }
}

document.getElementById('login-btn').addEventListener('click', tryLogin);
document.getElementById('secret-input').addEventListener('keydown', e => {
  if (e.key === 'Enter') tryLogin();
});

document.getElementById('logout-btn').addEventListener('click', () => {
  token = '';
  sessionStorage.removeItem('of_admin_token');
  showLogin();
});

// ── Load & render licenses ────────────────────────────────────────────────
async function loadLicenses() {
  const tbody = document.getElementById('license-tbody');
  tbody.innerHTML = '<tr><td colspan="6" class="empty-state"><span class="spinner"></span> Loading…</td></tr>';

  const res = await apiFetch('/admin/licenses');
  if (res.status === 401 || res.status === 403) {
    token = '';
    sessionStorage.removeItem('of_admin_token');
    showLogin('Session expired. Please sign in again.');
    return;
  }
  if (!res.ok) {
    tbody.innerHTML = '<tr><td colspan="6" class="empty-state">Failed to load licenses.</td></tr>';
    return;
  }

  const data = await res.json();
  allLicenses = data.licenses || [];
  updateStats();
  renderTable();
}

function updateStats() {
  let active = 0, expired = 0, revoked = 0;
  for (const lic of allLicenses) {
    const s = licenseStatus(lic);
    if (s === 'active')  active++;
    else if (s === 'expired') expired++;
    else if (s === 'revoked') revoked++;
  }
  document.getElementById('stat-total').textContent   = allLicenses.length;
  document.getElementById('stat-active').textContent  = active;
  document.getElementById('stat-expired').textContent = expired;
  document.getElementById('stat-revoked').textContent = revoked;
}

function renderTable() {
  const q = document.getElementById('search-input').value.toLowerCase();
  const filtered = q
    ? allLicenses.filter(l => l.email.toLowerCase().includes(q) || l.key.toLowerCase().includes(q))
    : allLicenses;

  const tbody = document.getElementById('license-tbody');
  if (filtered.length === 0) {
    tbody.innerHTML = '<tr><td colspan="6" class="empty-state">No licenses found.</td></tr>';
    return;
  }

  tbody.innerHTML = filtered.map(lic => {
    const status = licenseStatus(lic);
    const isRevoked = !lic.active;
    return ` + "`" + `
      <tr data-key="${esc(lic.key)}">
        <td class="key-cell" title="${esc(lic.key)}">${esc(truncateKey(lic.key))}</td>
        <td class="email-cell" title="${esc(lic.email)}">${esc(lic.email)}</td>
        <td>${formatDate(lic.createdAt)}</td>
        <td id="exp-${esc(lic.key)}">${formatDate(lic.expiresAt)}</td>
        <td><span class="badge ${status}">${status}</span></td>
        <td>
          <div class="action-group" id="actions-${esc(lic.key)}">
            ${isRevoked ? '' : ` + "`" + `
              <button class="btn-icon" onclick="showExtend('${esc(lic.key)}', '${lic.expiresAt || ''}')">Extend</button>
              <button class="btn-icon danger" onclick="showRevoke('${esc(lic.key)}')">Revoke</button>
            ` + "`" + `}
          </div>
        </td>
      </tr>
    ` + "`" + `;
  }).join('');
}

function esc(s) {
  return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;').replace(/'/g,'&#39;');
}

// ── Search ────────────────────────────────────────────────────────────────
document.getElementById('search-input').addEventListener('input', renderTable);
document.getElementById('refresh-btn').addEventListener('click', loadLicenses);

// ── Revoke ────────────────────────────────────────────────────────────────
function showRevoke(key) {
  const container = document.getElementById('actions-' + key);
  if (!container) return;
  container.innerHTML = ` + "`" + `
    <div class="revoke-row" style="display:flex;flex-direction:column;gap:6px;min-width:220px;">
      <textarea id="revoke-reason-${esc(key)}"
        placeholder="Reason (optional)…"
        rows="2"
        style="background:var(--bg);border:1px solid var(--border);border-radius:var(--radius);color:var(--text);font-size:12px;font-family:var(--sans);padding:6px 8px;resize:vertical;outline:none;width:100%;"
        onfocus="this.style.borderColor='var(--danger)'"
        onblur="this.style.borderColor='var(--border)'"
      ></textarea>
      <div style="display:flex;gap:6px;">
        <button class="btn-icon danger" onclick="submitRevoke('${esc(key)}')">Confirm Revoke</button>
        <button class="btn-icon" onclick="cancelRevoke('${esc(key)}')">✕ Cancel</button>
      </div>
    </div>
  ` + "`" + `;
}

function cancelRevoke(key) {
  const container = document.getElementById('actions-' + key);
  if (!container) return;
  const lic = allLicenses.find(l => l.key === key);
  const expiry = lic?.expiresAt || '';
  container.innerHTML = ` + "`" + `
    <button class="btn-icon" onclick="showExtend('${esc(key)}', '${esc(expiry)}')">Extend</button>
    <button class="btn-icon danger" onclick="showRevoke('${esc(key)}')">Revoke</button>
  ` + "`" + `;
}

async function submitRevoke(key) {
  const reasonEl = document.getElementById('revoke-reason-' + key);
  const reason = reasonEl ? reasonEl.value.trim() : '';

  const res = await apiFetch('/admin/licenses/' + encodeURIComponent(key), {
    method: 'DELETE',
    body: JSON.stringify({ reason }),
  });
  if (!res.ok) {
    toast('Failed to revoke license.', 'error');
    return;
  }
  toast('License revoked.', 'success');
  loadLicenses();
}

// ── Extend expiry ─────────────────────────────────────────────────────────
function showExtend(key, currentExpiry) {
  const container = document.getElementById('actions-' + key);
  if (!container) return;

  // Default to current expiry date or today + 1 year
  let defaultDate = '';
  if (currentExpiry) {
    defaultDate = currentExpiry.slice(0, 10);
  } else {
    const d = new Date();
    d.setFullYear(d.getFullYear() + 1);
    defaultDate = d.toISOString().slice(0, 10);
  }

  container.innerHTML = ` + "`" + `
    <div class="extend-row">
      <input type="date" id="ext-date-${esc(key)}" value="${esc(defaultDate)}">
      <button class="btn-icon" onclick="submitExtend('${esc(key)}')">Save</button>
      <button class="btn-icon" onclick="cancelExtend('${esc(key)}', '${esc(currentExpiry)}')">✕</button>
    </div>
  ` + "`" + `;
}

function cancelExtend(key, currentExpiry) {
  const container = document.getElementById('actions-' + key);
  if (!container) return;
  const isRevoked = !allLicenses.find(l => l.key === key)?.active;
  container.innerHTML = isRevoked ? '' : ` + "`" + `
    <button class="btn-icon" onclick="showExtend('${esc(key)}', '${esc(currentExpiry)}')">Extend</button>
    <button class="btn-icon danger" onclick="showRevoke('${esc(key)}')">Revoke</button>
  ` + "`" + `;
}

async function submitExtend(key) {
  const input = document.getElementById('ext-date-' + key);
  if (!input || !input.value) { toast('Please pick a date.', 'error'); return; }

  // Convert local date to RFC3339 (end of day UTC)
  const isoStr = input.value + 'T23:59:59Z';

  const res = await apiFetch('/admin/licenses/' + encodeURIComponent(key), {
    method: 'PATCH',
    body: JSON.stringify({ expiresAt: isoStr }),
  });
  if (!res.ok) {
    toast('Failed to update expiry.', 'error');
    return;
  }
  toast('Expiry updated.', 'success');
  loadLicenses();
}

// ── Create license ────────────────────────────────────────────────────────
document.getElementById('create-btn').addEventListener('click', async () => {
  const emailInput   = document.getElementById('create-email');
  const expiresInput = document.getElementById('create-expires');
  const btn          = document.getElementById('create-btn');

  const email = emailInput.value.trim();
  if (!email) { toast('Email is required.', 'error'); emailInput.focus(); return; }

  const body = { email };
  if (expiresInput.value) {
    body.expiresAt = expiresInput.value + 'T23:59:59Z';
  }

  btn.disabled = true;
  btn.textContent = 'Creating…';

  const res = await apiFetch('/admin/licenses', {
    method: 'POST',
    body: JSON.stringify(body),
  });

  btn.disabled = false;
  btn.textContent = 'Generate Key';

  if (!res.ok) {
    const txt = await res.text();
    toast('Error: ' + txt, 'error');
    return;
  }

  const data = await res.json();
  const keyResult = document.getElementById('key-result');
  const keyValue  = document.getElementById('key-value');
  keyValue.textContent = data.key;
  keyResult.style.display = 'flex';

  emailInput.value   = '';
  expiresInput.value = '';

  toast('License created!', 'success');
  loadLicenses();
});

document.getElementById('copy-btn').addEventListener('click', () => {
  const val = document.getElementById('key-value').textContent;
  navigator.clipboard.writeText(val).then(() => toast('Copied to clipboard.', 'success'));
});

// ── Boot ──────────────────────────────────────────────────────────────────
if (token) {
  // Try to restore session; if token is invalid, API call in loadLicenses will redirect to login
  showApp();
} else {
  showLogin();
}
</script>
</body>
</html>`
