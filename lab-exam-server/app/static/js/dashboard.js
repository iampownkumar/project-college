// ============================================================
// File: app/static/js/dashboard.js
// Project: Korelium Lab Exam System — Admin Dashboard
// Author: Pownkumar A
// ============================================================

// ── Config ──────────────────────────────────────────────────
const BASE = '';

let selectedSessionId = null;
let monitorTimer = null;
let parsedCsvStudents = [];

// ── API Helper ───────────────────────────────────────────────
async function api(method, path, body = null) {
  const opts = {
    method,
    headers: { 'Content-Type': 'application/json' },
  };
  if (body !== null) opts.body = JSON.stringify(body);
  const res = await fetch(BASE + path, opts);
  if (!res.ok) {
    const err = await res.json().catch(() => ({ detail: res.statusText }));
    throw new Error(err.detail || res.statusText);
  }
  if (res.status === 204) return null;
  return res.json();
}

// ── Toast ────────────────────────────────────────────────────
function toast(msg, type = 'info', duration = 3500) {
  const el = document.createElement('div');
  el.className = `toast ${type}`;
  el.innerHTML = `<span>${msg}</span>`;
  document.getElementById('toastContainer').appendChild(el);
  setTimeout(() => el.remove(), duration);
}

// ── Format helpers ───────────────────────────────────────────
function fmtTime(iso) {
  if (!iso) return '—';
  return new Date(iso).toLocaleString('en-IN', {
    timeZone: 'Asia/Kolkata',
    day: '2-digit', month: 'short',
    hour: '2-digit', minute: '2-digit',
  });
}
function timeSince(iso) {
  if (!iso) return 'never';
  const d = Math.floor((Date.now() - new Date(iso)) / 1000);
  if (d < 60)  return `${d}s ago`;
  if (d < 3600) return `${Math.floor(d/60)}m ago`;
  return `${Math.floor(d/3600)}h ago`;
}

// ════════════════════════════════════════════════════════════
//  INIT
// ════════════════════════════════════════════════════════════
function init() {
  loadSessions();
  checkServer();
  setInterval(checkServer, 10000);
}

async function checkServer() {
  try {
    await fetch(BASE + '/api/v1/health');
    document.getElementById('statusDot').className = 'status-dot online';
    document.getElementById('statusLabel').textContent = 'Server online';
  } catch {
    document.getElementById('statusDot').className = 'status-dot offline';
    document.getElementById('statusLabel').textContent = 'Server offline';
  }
}

// ════════════════════════════════════════════════════════════
//  SESSIONS SIDEBAR
// ════════════════════════════════════════════════════════════
async function loadSessions() {
  const list = document.getElementById('sessionList');
  list.innerHTML = `<div class="sidebar-loading"><div class="spinner"></div><span>Loading…</span></div>`;
  try {
    const sessions = await api('GET', '/api/v1/admin/sessions');
    renderSessionList(sessions);
  } catch (e) {
    list.innerHTML = `<div class="sidebar-loading" style="color:#f87171">Failed to load</div>`;
  }
}

function renderSessionList(sessions) {
  const list = document.getElementById('sessionList');
  if (!sessions.length) {
    list.innerHTML = `<div class="sidebar-loading" style="color:var(--text-dim)">No sessions yet</div>`;
    return;
  }
  // Sort: active first, then draft, then closed
  const order = { active: 0, draft: 1, closed: 2 };
  sessions.sort((a, b) => order[a.status] - order[b.status]);

  list.innerHTML = sessions.map(s => `
    <div class="session-card ${s.id === selectedSessionId ? 'active' : ''}"
         id="sc-${s.id}" onclick="selectSession(${s.id})">
      <div class="session-card-title">${esc(s.title)}</div>
      <div class="session-card-meta">
        <span class="badge badge-${s.status}">${s.status}</span>
        <span class="session-card-dept">${esc(s.department)}</span>
      </div>
    </div>
  `).join('');
}

async function selectSession(id) {
  selectedSessionId = id;
  stopMonitor();

  // Update sidebar highlight
  document.querySelectorAll('.session-card').forEach(c => c.classList.remove('active'));
  const card = document.getElementById(`sc-${id}`);
  if (card) card.classList.add('active');

  // Show view
  document.getElementById('emptyState').classList.add('hidden');
  document.getElementById('sessionView').classList.remove('hidden');

  try {
    const s = await api('GET', `/api/v1/admin/session/${id}`);
    renderSessionHeader(s);
  } catch (e) {
    toast('Failed to load session: ' + e.message, 'error');
  }

  // Default to students tab
  switchTab('students');
}

function renderSessionHeader(s) {
  document.getElementById('viewTitle').textContent = s.title;
  const statusEl = document.getElementById('viewStatus');
  statusEl.className = `badge badge-${s.status}`;
  statusEl.textContent = s.status;

  document.getElementById('viewMeta').innerHTML = [
    `<span>${esc(s.department)}</span>`,
    `<span>${s.language.toUpperCase()}</span>`,
    `<span>${s.duration_minutes} min</span>`,
    s.start_time ? `<span>Start: ${fmtTime(s.start_time)}</span>` : '',
    s.end_time   ? `<span>End: ${fmtTime(s.end_time)}</span>`   : '',
    `<span>${s.question_count} Q · ${s.student_count} students</span>`,
  ].filter(Boolean).join('');

  // Button visibility based on status
  document.getElementById('activateBtn').style.display = s.status === 'draft'   ? '' : 'none';
  document.getElementById('closeBtn').style.display    = s.status === 'active'  ? '' : 'none';
}

// ── Session Actions ──────────────────────────────────────────
async function setSessionStatus(status) {
  try {
    await api('PUT', `/api/v1/admin/session/${selectedSessionId}/status`, { status });
    toast(`Session ${status}`, 'success');
    loadSessions();
    selectSession(selectedSessionId);
  } catch (e) {
    toast(e.message, 'error');
  }
}

async function deleteCurrentSession() {
  if (!confirm('Delete this session and all its data?')) return;
  try {
    await api('DELETE', `/api/v1/admin/session/${selectedSessionId}`);
    toast('Session deleted', 'success');
    selectedSessionId = null;
    document.getElementById('sessionView').classList.add('hidden');
    document.getElementById('emptyState').classList.remove('hidden');
    loadSessions();
  } catch (e) {
    toast(e.message, 'error');
  }
}

// ── New Session Modal ────────────────────────────────────────
function openNewSessionModal() {
  document.getElementById('newSessionModal').classList.remove('hidden');
  document.getElementById('m_title').focus();
}
function closeNewSessionModal() {
  document.getElementById('newSessionModal').classList.add('hidden');
}
async function createSession() {
  const title    = document.getElementById('m_title').value.trim();
  const dept     = document.getElementById('m_dept').value.trim();
  const duration = parseInt(document.getElementById('m_duration').value) || 60;
  if (!title || !dept) { toast('Title and department are required', 'error'); return; }
  try {
    const s = await api('POST', '/api/v1/admin/session', { title, department: dept, duration_minutes: duration });
    toast('Session created', 'success');
    closeNewSessionModal();
    document.getElementById('m_title').value = '';
    document.getElementById('m_dept').value = '';
    document.getElementById('m_duration').value = '60';
    await loadSessions();
    selectSession(s.id);
  } catch (e) {
    toast(e.message, 'error');
  }
}

// ════════════════════════════════════════════════════════════
//  TABS
// ════════════════════════════════════════════════════════════
function switchTab(name) {
  document.querySelectorAll('.tab').forEach(t => t.classList.toggle('active', t.dataset.tab === name));
  document.querySelectorAll('.tab-content').forEach(c => c.classList.add('hidden'));
  document.getElementById(`tab-${name}`).classList.remove('hidden');
  stopMonitor();
  if (name === 'students')    loadStudents();
  if (name === 'monitor')     startMonitor();
  if (name === 'submissions') loadSubmissions();
}

// ════════════════════════════════════════════════════════════
//  STUDENTS
// ════════════════════════════════════════════════════════════
async function loadStudents() {
  const tbody = document.getElementById('studentsBody');
  tbody.innerHTML = `<tr><td colspan="8" class="empty-row"><div class="spinner" style="margin:auto"></div></td></tr>`;
  try {
    const students = await api('GET', '/api/v1/admin/students');
    renderStudents(students);
  } catch (e) {
    tbody.innerHTML = `<tr><td colspan="8" class="empty-row" style="color:#f87171">Failed to load</td></tr>`;
  }
}

function renderStudents(students) {
  const tbody = document.getElementById('studentsBody');
  document.getElementById('studentCount').textContent = `${students.length} student${students.length !== 1 ? 's' : ''}`;
  if (!students.length) {
    tbody.innerHTML = `<tr><td colspan="8" class="empty-row">No students yet — upload a CSV or add one manually</td></tr>`;
    return;
  }
  tbody.innerHTML = students.map(s => `
    <tr>
      <td><span style="font-family:'JetBrains Mono',monospace;font-size:12px">${esc(s.registration_number)}</span></td>
      <td>${esc(s.name)}</td>
      <td>${esc(s.department)}</td>
      <td>${esc(s.batch)}</td>
      <td>${esc(s.year)}</td>
      <td>${esc(s.section)}</td>
      <td>
        <span class="badge ${s.enabled ? 'badge-enabled' : 'badge-disabled'}">
          ${s.enabled ? 'Active' : 'Disabled'}
        </span>
      </td>
      <td>
        <div class="row-actions">
          <button class="action-link ${s.enabled ? 'warn' : 'muted'}"
            onclick="${s.enabled ? 'disableStudent' : 'enableStudent'}('${esc(s.registration_number)}')">
            ${s.enabled ? 'Disable' : 'Enable'}
          </button>
          <button class="action-link danger" onclick="deleteStudent('${esc(s.registration_number)}')">Delete</button>
        </div>
      </td>
    </tr>
  `).join('');
}

async function enableStudent(reg)  {
  try { await api('PUT', `/api/v1/admin/student/${reg}/enable`);  loadStudents(); } catch(e) { toast(e.message,'error'); }
}
async function disableStudent(reg) {
  try { await api('PUT', `/api/v1/admin/student/${reg}/disable`); loadStudents(); } catch(e) { toast(e.message,'error'); }
}
async function deleteStudent(reg) {
  if (!confirm(`Delete student ${reg}?`)) return;
  try { await api('DELETE', `/api/v1/admin/student/${reg}`); toast('Deleted','success'); loadStudents(); } catch(e) { toast(e.message,'error'); }
}
async function deleteAllStudents() {
  if (!confirm('Delete ALL students? This cannot be undone.')) return;
  try { await api('DELETE', '/api/v1/admin/students/all'); toast('All students deleted','success'); loadStudents(); } catch(e) { toast(e.message,'error'); }
}

// ── Add One ──────────────────────────────────────────────────
function toggleAddOne() {
  const p = document.getElementById('addOnePanel');
  p.classList.toggle('hidden');
  if (!p.classList.contains('hidden')) {
    document.getElementById('csvPanel').classList.add('hidden');
    document.getElementById('f_reg').focus();
  }
}
async function saveOne() {
  const payload = {
    registration_number: document.getElementById('f_reg').value.trim(),
    name:       document.getElementById('f_name').value.trim(),
    department: document.getElementById('f_dept').value.trim(),
    batch:      document.getElementById('f_batch').value.trim(),
    year:       document.getElementById('f_year').value.trim(),
    section:    document.getElementById('f_section').value.trim(),
  };
  if (!payload.registration_number || !payload.name || !payload.department || !payload.batch || !payload.year || !payload.section) {
    toast('All fields are required', 'error'); return;
  }
  try {
    await api('POST', '/api/v1/admin/student', payload);
    toast('Student added', 'success');
    document.getElementById('addOnePanel').classList.add('hidden');
    ['f_reg','f_name','f_dept','f_batch','f_year','f_section'].forEach(id => document.getElementById(id).value = '');
    loadStudents();
  } catch (e) {
    toast(e.message, 'error');
  }
}

// ── CSV Upload ───────────────────────────────────────────────
function toggleCsvPanel() {
  const p = document.getElementById('csvPanel');
  p.classList.toggle('hidden');
  if (!p.classList.contains('hidden')) {
    document.getElementById('addOnePanel').classList.add('hidden');
  }
}

function handleCsvFile(file) {
  if (!file) return;
  const reader = new FileReader();
  reader.onload = e => {
    try {
      parsedCsvStudents = parseCSV(e.target.result);
      renderCsvPreview(parsedCsvStudents);
    } catch (err) {
      toast('CSV parse error: ' + err.message, 'error');
    }
  };
  reader.readAsText(file);
}

function parseCSV(text) {
  const lines = text.trim().split('\n').map(l => l.trim()).filter(Boolean);
  if (lines.length < 2) throw new Error('CSV must have a header and at least one data row');

  const headers = lines[0].split(',').map(h => h.trim().toLowerCase().replace(/\s+/g,'_'));
  const REQUIRED = ['registration_number','name','department','batch','year','section'];
  const missing = REQUIRED.filter(r => !headers.includes(r));
  if (missing.length) throw new Error(`Missing columns: ${missing.join(', ')}`);

  return lines.slice(1).map((line, i) => {
    // handle quoted fields
    const vals = [];
    let current = ''; let inQuote = false;
    for (const ch of line) {
      if (ch === '"') { inQuote = !inQuote; }
      else if (ch === ',' && !inQuote) { vals.push(current.trim()); current = ''; }
      else { current += ch; }
    }
    vals.push(current.trim());

    const row = {};
    headers.forEach((h, idx) => { row[h] = vals[idx] || ''; });

    for (const r of REQUIRED) {
      if (!row[r]) throw new Error(`Row ${i+2}: missing "${r}"`);
    }
    return row;
  });
}

function renderCsvPreview(rows) {
  const preview = document.getElementById('csvPreview');
  const cols = ['registration_number','name','department','batch','year','section'];
  const colLabels = ['Reg. No.','Name','Dept','Batch','Year','Sec'];
  preview.innerHTML = `
    <table>
      <thead><tr>${colLabels.map(l=>`<th>${l}</th>`).join('')}</tr></thead>
      <tbody>
        ${rows.slice(0, 10).map(r => `<tr>${cols.map(c=>`<td>${esc(r[c]||'')}</td>`).join('')}</tr>`).join('')}
        ${rows.length > 10 ? `<tr><td colspan="${cols.length}" style="text-align:center;color:var(--text-muted);padding:8px">…and ${rows.length-10} more rows</td></tr>` : ''}
      </tbody>
    </table>
  `;
  preview.classList.remove('hidden');
  document.getElementById('csvActions').classList.remove('hidden');
}

async function confirmUpload() {
  if (!parsedCsvStudents.length) return;
  const btn = document.getElementById('confirmUploadBtn');
  btn.disabled = true; btn.textContent = 'Uploading…';
  try {
    const result = await api('POST', '/api/v1/admin/students/bulk', { students: parsedCsvStudents });
    toast(`✓ ${result.created} created, ${result.skipped} skipped${result.errors.length ? ` — ${result.errors.length} errors` : ''}`, result.errors.length ? 'info' : 'success', 5000);
    closeCsvPanel();
    loadStudents();
  } catch (e) {
    toast(e.message, 'error');
  } finally {
    btn.disabled = false; btn.textContent = 'Upload Students';
  }
}

function closeCsvPanel() {
  document.getElementById('csvPanel').classList.add('hidden');
  document.getElementById('csvPreview').classList.add('hidden');
  document.getElementById('csvActions').classList.add('hidden');
  document.getElementById('csvFileInput').value = '';
  parsedCsvStudents = [];
}

// ════════════════════════════════════════════════════════════
//  LIVE MONITOR
// ════════════════════════════════════════════════════════════
function startMonitor() {
  fetchMonitor();
  monitorTimer = setInterval(fetchMonitor, 5000);
}
function stopMonitor() {
  if (monitorTimer) { clearInterval(monitorTimer); monitorTimer = null; }
}

async function fetchMonitor() {
  if (!selectedSessionId) return;
  try {
    const data = await api('GET', `/api/v1/admin/session/${selectedSessionId}/monitor`);
    renderMonitor(data);
  } catch {/* silently fail on poll */}
}

function renderMonitor(data) {
  document.getElementById('monitorStats').innerHTML = `
    <div class="stat-pill"><span class="num">${data.total_students}</span><span class="lbl">total</span></div>
    <div class="stat-pill"><span class="num" style="color:var(--green)">${data.online_count}</span><span class="lbl">online</span></div>
    <div class="stat-pill"><span class="num" style="color:var(--accent)">${data.submitted_count}</span><span class="lbl">submitted</span></div>
  `;
  const tbody = document.getElementById('monitorBody');
  if (!data.students.length) {
    tbody.innerHTML = `<tr><td colspan="7" class="empty-row">No students in this session</td></tr>`;
    return;
  }
  tbody.innerHTML = data.students.map(s => `
    <tr>
      <td>${esc(s.name)}</td>
      <td><span style="font-family:'JetBrains Mono',monospace;font-size:12px">${esc(s.registration_number)}</span></td>
      <td>${s.machine_ip ? `${esc(s.machine_name||'')} <span style="color:var(--text-dim);font-size:11px">${esc(s.machine_ip)}</span>` : '<span style="color:var(--text-dim)">—</span>'}</td>
      <td>
        <span class="badge ${s.is_online ? 'badge-online' : 'badge-offline'}">
          ${s.is_online ? 'Online' : 'Offline'}
        </span>
        ${s.client_state && s.client_state !== 'idle' ? `<span class="badge badge-running" style="margin-left:4px">${esc(s.client_state)}</span>` : ''}
      </td>
      <td>${s.run_count}</td>
      <td>
        ${s.has_submitted
          ? `<span class="badge badge-submitted">Submitted</span>`
          : `<span style="color:var(--text-dim)">—</span>`}
      </td>
      <td style="color:var(--text-muted);font-size:12px">${timeSince(s.last_seen_at)}</td>
    </tr>
  `).join('');
}

// ════════════════════════════════════════════════════════════
//  SUBMISSIONS
// ════════════════════════════════════════════════════════════
async function loadSubmissions() {
  const tbody = document.getElementById('submissionsBody');
  tbody.innerHTML = `<tr><td colspan="6" class="empty-row"><div class="spinner" style="margin:auto"></div></td></tr>`;
  try {
    const subs = await api('GET', `/api/v1/admin/session/${selectedSessionId}/submissions`);
    renderSubmissions(subs);
  } catch (e) {
    tbody.innerHTML = `<tr><td colspan="6" class="empty-row" style="color:#f87171">Failed to load</td></tr>`;
  }
}

function renderSubmissions(subs) {
  const tbody = document.getElementById('submissionsBody');
  if (!subs.length) {
    tbody.innerHTML = `<tr><td colspan="6" class="empty-row">No submissions yet</td></tr>`;
    return;
  }
  const typeColors = { normal: 'badge-submitted', auto_tab_switch: 'badge-running', auto_timer: 'badge-closed', resubmission: 'badge-draft' };
  tbody.innerHTML = subs.map(s => `
    <tr>
      <td>${esc(s.student_name || '—')}</td>
      <td><span style="font-family:'JetBrains Mono',monospace;font-size:12px">${esc(s.registration_number || '—')}</span></td>
      <td style="max-width:200px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap" title="${esc(s.question_title||'')}">
        ${esc(s.question_title || '—')}
      </td>
      <td>
        <span style="font-family:'JetBrains Mono',monospace;color:${s.exit_code === 0 ? 'var(--green)' : 'var(--red)'}">
          ${s.exit_code !== null && s.exit_code !== undefined ? s.exit_code : '—'}
        </span>
      </td>
      <td><span class="badge ${typeColors[s.submission_type] || 'badge-draft'}">${esc(s.submission_type || 'normal')}</span></td>
      <td style="color:var(--text-muted);font-size:12px">${fmtTime(s.submitted_at)}</td>
    </tr>
  `).join('');
}

// ── Escape HTML ──────────────────────────────────────────────
function esc(str) {
  if (str === null || str === undefined) return '';
  return String(str)
    .replace(/&/g,'&amp;')
    .replace(/</g,'&lt;')
    .replace(/>/g,'&gt;')
    .replace(/"/g,'&quot;');
}

// ════════════════════════════════════════════════════════════
//  EVENT LISTENERS
// ════════════════════════════════════════════════════════════
document.addEventListener('DOMContentLoaded', () => {

  // Sessions sidebar
  document.getElementById('newSessionBtn').addEventListener('click', openNewSessionModal);
  document.getElementById('emptyNewBtn').addEventListener('click', openNewSessionModal);
  document.getElementById('refreshSessionsBtn').addEventListener('click', loadSessions);

  // Session actions
  document.getElementById('activateBtn').addEventListener('click', () => setSessionStatus('active'));
  document.getElementById('closeBtn').addEventListener('click', () => setSessionStatus('closed'));
  document.getElementById('deleteSessionBtn').addEventListener('click', deleteCurrentSession);

  // New session modal
  document.getElementById('createSessionBtn').addEventListener('click', createSession);
  document.getElementById('cancelModalBtn').addEventListener('click', closeNewSessionModal);
  document.getElementById('closeModalBtn').addEventListener('click', closeNewSessionModal);
  document.getElementById('newSessionModal').addEventListener('click', e => {
    if (e.target === document.getElementById('newSessionModal')) closeNewSessionModal();
  });

  // Tabs
  document.querySelectorAll('.tab').forEach(t => {
    t.addEventListener('click', () => switchTab(t.dataset.tab));
  });

  // Students
  document.getElementById('uploadCsvBtn').addEventListener('click', toggleCsvPanel);
  document.getElementById('addOneBtn').addEventListener('click', toggleAddOne);
  document.getElementById('deleteAllStudentsBtn').addEventListener('click', deleteAllStudents);
  document.getElementById('closeCsvPanel').addEventListener('click', closeCsvPanel);
  document.getElementById('confirmUploadBtn').addEventListener('click', confirmUpload);
  document.getElementById('cancelUploadBtn').addEventListener('click', closeCsvPanel);
  document.getElementById('saveOneBtn').addEventListener('click', saveOne);
  document.getElementById('cancelOneBtn').addEventListener('click', () => document.getElementById('addOnePanel').classList.add('hidden'));

  // CSV file input
  const fileInput = document.getElementById('csvFileInput');
  fileInput.addEventListener('change', () => handleCsvFile(fileInput.files[0]));

  // Drag and drop
  const dropZone = document.getElementById('csvDropZone');
  dropZone.addEventListener('click', () => fileInput.click());
  dropZone.addEventListener('dragover', e => { e.preventDefault(); dropZone.classList.add('drag-over'); });
  dropZone.addEventListener('dragleave', () => dropZone.classList.remove('drag-over'));
  dropZone.addEventListener('drop', e => {
    e.preventDefault();
    dropZone.classList.remove('drag-over');
    handleCsvFile(e.dataTransfer.files[0]);
  });

  init();
});
